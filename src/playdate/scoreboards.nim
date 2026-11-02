{.push raises: [].}

import std/[importutils, macros, sequtils]

import types {.all.}
import bindings/[api, types, utils]
import bindings/scoreboards

# Only export public symbols, then import all
export scoreboards
{.hint[DuplicateModuleImport]: off.}
import bindings/scoreboards {.all.}

type
  PDScore* = object of RootObj
    value*, rank*: uint32
    player*: string

  PDScoresList* = object of RootObj
    boardID*: string
    lastUpdated*: uint32
    scores*: seq[PDScore]
    # these properties are not implemented yet in the Playdate API
    # playerIncluded*: uint32
    # limit*: uint32

  PDBoard* = object of RootObj
    boardID*, name*: string

  PDBoardsList* = object of RootObj
    lastUpdated*: uint32
    boards*: seq[PDBoard]

  PDResultKind* = enum
    PDResultSuccess
    PDResultUnavailable
      ## The operation completed successfully, but the response had no data
    PDResultError

  PDResult*[T] = object
    case kind*: PDResultKind
    of PDResultSuccess: result*: T
    of PDResultUnavailable: discard
    of PDResultError: message*: string

  PersonalBestCallback* = proc(result: PDResult[PDScore]) {.raises: [].}
  AddScoreCallback* = proc(result: PDResult[PDScore]) {.raises: [].}
  BoardsListCallback* = proc(result: PDResult[PDBoardsList]) {.raises: [].}
  ScoresCallback* = proc(result: PDResult[PDScoresList]) {.raises: [].}

const scoreboardSlots* {.intDefine.} = 16
  ## How many requests of each kind can wait for a reply at once. Override with
  ## `-d:scoreboardSlots=N`. A request made while every slot is taken fails immediately.

static:
  doAssert scoreboardSlots >= 1, "scoreboardSlots must be at least 1"

type
  Callback[T] = proc(result: PDResult[T]) {.raises: [].}

  CallbackSlots[T] = object
    ## The SDK callbacks have no userdata field, so each pending request is handed its own C
    ## trampoline. The slot index built into that trampoline says which callback a reply belongs to.
    ## A slot is only freed by its reply: the SDK may still call a trampoline whose request we have
    ## given up on, so reusing it early would hand that reply to the wrong callback.
    callbacks: array[scoreboardSlots, Callback[T]]

var
  personalBestSlots: CallbackSlots[PDScore]
  addScoreSlots: CallbackSlots[PDScore]
  scoresSlots: CallbackSlots[PDScoresList]
  boardsListSlots: CallbackSlots[PDBoardsList]

proc take[T](slots: var CallbackSlots[T], index: int): auto =
  result = slots.callbacks[index]
  slots.callbacks[index] = nil

proc findAvailable[T](slots: CallbackSlots[T]): int =
  ## The first free slot, or -1 if every slot is pending
  for i in 0 ..< scoreboardSlots:
    if slots.callbacks[i] == nil:
      return i
  return -1

template withClaim[T](
    slots: var CallbackSlots[T], callback: Callback[T], body: untyped
) =
  ## Claims a slot for `callback` and runs `body`, which sends the request using the injected
  ## `slot`. The slot is claimed first in case the SDK responds synchronously. If every slot is
  ## pending, the callback gets an error right away and the request is never sent.
  let slot {.inject.} = slots.findAvailable()
  if slot < 0:
    const noSlotsMsg = "Too many pending scoreboard requests"
    callback(PDResult[T](kind: PDResultError, message: noSlotsMsg))
  else:
    slots.callbacks[slot] = callback
    discard body

template invokeCallback(
    slots, index, value, errorMessage, freeValue, builder: untyped
) =
  type ResultType = typeof(builder)
  # The slot is freed before the callback runs, so the callback can make a new request
  let callback = slots.take(index)
  if callback == nil:
    # A reply for a slot with no pending request has nowhere to go, but still owns its data
    if value != nil:
      freeValue(value)
    return
  if value == nil:
    if errorMessage == nil:
      callback(PDResult[ResultType](kind: PDResultUnavailable))
    else:
      callback(PDResult[ResultType](kind: PDResultError, message: $errorMessage))
  else:
    try:
      let built = builder
      callback(PDResult[ResultType](kind: PDResultSuccess, result: built))
    finally:
      freeValue(value)

proc scoreBuilder(score: PDScoreRaw | PDScorePtr | PDListScoreRaw): PDScore =
  PDSCore(value: score.value.uint32, rank: score.rank.uint32, player: $score.player)

proc dispatchPersonalBest(index: int, score: PDScorePtr, errorMessage: ConstChar) =
  invokeCallback(
    personalBestSlots, index, score, errorMessage, playdate.scoreboards.freeScore
  ):
    scoreBuilder(score)

proc dispatchAddScore(index: int, score: PDScorePtr, errorMessage: ConstChar) =
  invokeCallback(
    addScoreSlots, index, score, errorMessage, playdate.scoreboards.freeScore
  ):
    scoreBuilder(score)

proc dispatchScores(index: int, scoresList: PDScoresListPtr, errorMessage: ConstChar) =
  invokeCallback(
    scoresSlots, index, scoresList, errorMessage, playdate.scoreboards.freeScoresList
  ):
    let scoresSeq =
      scoresList.scores.items(scoresList.count).toSeq.mapIt(scoreBuilder(it))
    PDScoresList(
      boardID: $scoresList.boardID,
      lastUpdated: scoresList.lastUpdated,
      scores: scoresSeq,
    )

proc dispatchBoardsList(
    index: int, boardsList: PDBoardsListPtr, errorMessage: ConstChar
) =
  invokeCallback(
    boardsListSlots, index, boardsList, errorMessage,
    playdate.scoreboards.freeBoardsList,
  ):
    let boardsSeq = boardsList.boards.items(boardsList.count).toSeq.mapIt(
        PDBoard(boardID: $it.boardID, name: $it.name)
      )
    PDBoardsList(lastUpdated: boardsList.lastUpdated, boards: boardsSeq)

macro trampolineTable(
    dispatch: typed, ValueType: typedesc, RawType: typedesc
): untyped =
  ## Declares one cdecl trampoline per slot, each calling `dispatch(<slot index>, value,
  ## errorMessage)`, and builds `[RawType(trampoline0), RawType(trampoline1), ...]`. Each slot
  ## needs its own C function address so that the address the SDK calls back identifies the
  ## request.
  var body = newStmtList()
  var table = nnkBracket.newTree()
  for i in 0 ..< scoreboardSlots:
    let name = genSym(nskProc, "trampoline")
    body.add quote do:
      proc `name`(value: `ValueType`, errorMessage: ConstChar) {.cdecl, raises: [].} =
        `dispatch`(`i`, value, errorMessage)

    table.add quote do:
      `RawType`(`name`)
  body.add table
  return newBlockStmt(body)

const
  personalBestTrampolines =
    trampolineTable(dispatchPersonalBest, PDScorePtr, PersonalBestCallbackRaw)
  addScoreTrampolines =
    trampolineTable(dispatchAddScore, PDScorePtr, AddScoreCallbackRaw)
  scoresTrampolines =
    trampolineTable(dispatchScores, PDScoresListPtr, ScoresCallbackRaw)
  boardsListTrampolines =
    trampolineTable(dispatchBoardsList, PDBoardsListPtr, BoardsListCallbackRaw)

proc getPersonalBest*(
    this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback
) =
  ## Responds with PDResultUnavailable if no score exists for the current player.
  privateAccess(PlaydateScoreboards)
  personalBestSlots.withClaim(callback):
    this.getPersonalBestBinding(boardID.cstring, personalBestTrampolines[slot])

proc addScore*(
    this: ptr PlaydateScoreboards,
    boardID: string,
    value: uint32,
    callback: AddScoreCallback,
) =
  ## Responds with PDResultUnavailable if the score was queued for later submission. Probably, Wi-Fi is not available.
  privateAccess(PlaydateScoreboards)
  addScoreSlots.withClaim(callback):
    this.addScoreBinding(boardID.cstring, value.cuint, addScoreTrampolines[slot])

proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback) =
  privateAccess(PlaydateScoreboards)
  boardsListSlots.withClaim(callback):
    this.getScoreboardsBinding(boardsListTrampolines[slot])

proc getScores*(
    this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback
) =
  privateAccess(PlaydateScoreboards)
  scoresSlots.withClaim(callback):
    this.getScoresBinding(boardID.cstring, scoresTrampolines[slot])

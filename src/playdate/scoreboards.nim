{.push raises: [].}

import std/importutils

import types {.all.}
import bindings/[api, types]
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

  PersonalBestCallback* = proc(score: PDScore, errorMessage: string)
  AddScoreCallback* = proc(score: PDScore, errorMessage: string)
  BoardsListCallback* = proc(boards: PDBoardsList, errorMessage: string)
  ScoresCallback* = proc(scores: PDScoresList, errorMessage: string)

var
  # The sdk callbacks unfortunately don't provide a userdata field to tag the callback with eg. the boardID
  # So we need to keep track of the callbacks in the order they were called, which luckily is guaranteed by the Playdate API
  # By inserting the callback at the start, it will be popped last: first in, first out
  privatePersonalBestCallbacks = newSeq[PersonalBestCallback]()
  privateAddScoreCallbacks = newSeq[AddScoreCallback]()
  privateScoresCallbacks = newSeq[ScoresCallback]()
  privateBoardsListCallbacks = newSeq[BoardsListCallback]()

template invokeCallback(callbackSeqs, value, errorMessage, freeValue, builder, emptyValue: untyped) =
  let callback = callbackSeqs.pop()
  if value == nil and errorMessage == nil:
      callback(emptyValue, "Playdate-nim: No value provided for callback")
      return

  if value == nil:
    callback(emptyValue, $errorMessage)
    return

  try:
    let nimObj = builder(value)
    callback(nimObj, $errorMessage)
  finally:
    freeValue(value)


proc newPDScore(value: uint32, rank: uint32, player: string): PDScore =
  PDSCore(value: value, rank: rank, player: player)
let emptyPDScore = newPDScore(value = 0, rank = 0, player = "")

proc newPDScoresList(boardID: string, lastUpdated: uint32, scores: seq[PDScore]): PDScoresList =
  PDScoresList(boardID: boardID, lastUpdated: lastUpdated, scores: scores)
let emptyPDScoresList = newPDScoresList(boardID = "", lastUpdated = 0, scores = @[])

proc newPDBoard(boardID: string, name: string): PDBoard =
  PDBoard(boardID: boardID, name: name)

proc newPDBoardsList(lastUpdated: uint32, boards: seq[PDBoard]): PDBoardsList =
  PDBoardsList(lastUpdated: lastUpdated, boards: boards)
let emptyPDBoardsList = newPDBoardsList(lastUpdated = 0, boards = @[])

proc scoreBuilder(score: PDScorePtr): PDScore =
  newPDScore(
    value = score.value.uint32,
    rank = score.rank.uint32,
    player = $score.player
  )

proc scoreBuilder(score: PDScoreRaw): PDScore =
  newPDScore(
    value = score.value.uint32,
    rank = score.rank.uint32,
    player = $score.player
  )

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  invokeCallback(
    callbackSeqs = privatePersonalBestCallbacks,
    value = score,
    errorMessage = errorMessage,
    freeValue = playdate.scoreboards.freeScore,
    builder = scoreBuilder,
    emptyValue = emptyPDScore
  )

proc invokeAddScoreCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  invokeCallback(
    callbackSeqs = privateAddScoreCallbacks,
    value = score,
    errorMessage = errorMessage,
    freeValue = playdate.scoreboards.freeScore,
    builder = scoreBuilder,
    emptyValue = emptyPDScore
  )

proc seqBuilder[T, U](rawField: ptr UncheckedArray[T], length: cuint, itemBuilder: proc (item: T): U {.raises: [].}): seq[U] =
  privateAccess(SDKArray)
  let cArray = SDKArray[T](data: rawField, len: length.int)
  var newSeq = newSeq[U](length)
  for i in 0 ..< length:
    let item = cArray[i]
    newSeq[i] = itemBuilder(item)
  cArray.data = nil # no need for SDKArray to free the data, free function will do it
  return newSeq

proc invokeScoresCallback(scoresList: PDScoresListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  invokeCallback(
    callbackSeqs = privateScoresCallbacks,
    value = scoresList,
    errorMessage = errorMessage,
    freeValue = playdate.scoreboards.freeScoresList,
    builder = proc (scoresList: PDScoresListPtr): PDScoresList =
      privateAccess(SDKArray)
      var scoresSeq = seqBuilder(
        rawField = scoresList.scores,
        length = scoresList.count,
        itemBuilder = scoreBuilder
      )

      return newPDScoresList(boardID = $scoresList.boardID, lastUpdated = scoresList.lastUpdated, scores = scoresSeq),
    emptyValue = emptyPDScoresList
  )

proc invokeBoardsListCallback(boardsList: PDBoardsListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  invokeCallback(
    callbackSeqs = privateBoardsListCallbacks,
    value = boardsList,
    errorMessage = errorMessage,
    freeValue = playdate.scoreboards.freeBoardsList,
    builder = proc (boardsList: PDBoardsListPtr): PDBoardsList =
      privateAccess(SDKArray)
      var boardsSeq = seqBuilder(
      rawField = cast[ptr UncheckedArray[PDBoardRaw]](boardsList.boards),
      length = boardsList.count,
      itemBuilder = proc (board: PDBoardRaw): PDBoard =
        newPDBoard(boardID = $board.boardID, name = $board.name)
      )

      return newPDBoardsList(lastUpdated = boardsList.lastUpdated, boards = boardsSeq),
    emptyValue = emptyPDBoardsList
  )

proc getPersonalBest*(this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback): int32 {.discardable.} =
  privateAccess(PlaydateScoreboards)
  privatePersonalBestCallbacks.insert(callback) # by inserting the callback at the start, it will be popped last: first in, first out
  return this.getPersonalBestBinding(boardID.cstring, invokePersonalBestCallback)

proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 {.discardable.} =
  privateAccess(PlaydateScoreboards)
  privateAddScoreCallbacks.insert(callback) # by inserting the callback at the start, it will be popped last: first in, first out
  return this.addScoreBinding(boardID.cstring, value.cuint, invokeAddScoreCallback)

proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback): int32 {.discardable.} =
  privateAccess(PlaydateScoreboards)
  privateBoardsListCallbacks.insert(callback) # by inserting the callback at the start, it will be popped last: first in, first out
  return this.getScoreboardsBinding(invokeBoardsListCallback)

proc getScores*(this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback): int32 {.discardable.} =
  privateAccess(PlaydateScoreboards)
  privateScoresCallbacks.insert(callback) # by inserting the callback at the start, it will be popped last: first in, first out
  return this.getScoresBinding(boardID.cstring, invokeScoresCallback)
{.push raises: [].}

import std/[importutils, sequtils]

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

    PersonalBestCallback* = proc(score: PDScore, errorMessage: string) {.raises: [].}
    AddScoreCallback* = proc(score: PDScore, errorMessage: string) {.raises: [].}
    BoardsListCallback* = proc(boards: PDBoardsList, errorMessage: string) {.raises: [].}
    ScoresCallback* = proc(scores: PDScoresList, errorMessage: string) {.raises: [].}

var
    # The sdk callbacks unfortunately don't provide a userdata field to tag the callback with eg. the boardID
    # Scoreboard responses are handled in order of request, however, so if we keep track of request order everything should be fine.
    # By inserting the callback at the start, it will be popped last: first in, first out
    privatePersonalBestCallbacks = newSeq[PersonalBestCallback]()
    privateAddScoreCallbacks = newSeq[AddScoreCallback]()
    privateScoresCallbacks = newSeq[ScoresCallback]()
    privateBoardsListCallbacks = newSeq[BoardsListCallback]()

template invokeCallback(callbackSeqs, value, errorMessage, freeValue, builder: untyped) =
  let callback = callbackSeqs.pop()
  if value == nil and errorMessage == nil:
      callback(default(typeof(builder)), "Playdate-nim: No value provided for callback")
      return

  if value == nil:
    callback(default(typeof(builder)), $errorMessage)
    return

  try:
    let nimObj = builder
    callback(nimObj, $errorMessage)
  finally:
    freeValue(value)

proc scoreBuilder(score: PDScoreRaw | PDScorePtr): PDScore =
    PDSCore(value: score.value.uint32, rank: score.rank.uint32, player: $score.player)

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
    invokeCallback(privatePersonalBestCallbacks, score, errorMessage, playdate.scoreboards.freeScore):
        scoreBuilder(score)

proc invokeAddScoreCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
    invokeCallback(privateAddScoreCallbacks, score, errorMessage, playdate.scoreboards.freeScore):
        scoreBuilder(score)

proc invokeScoresCallback(scoresList: PDScoresListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
    invokeCallback(privateScoresCallbacks, scoresList, errorMessage, playdate.scoreboards.freeScoresList):
        let scoresSeq = scoresList.scores.items(scoresList.count).toSeq.mapIt(scoreBuilder(it))
        PDScoresList(boardID: $scoresList.boardID, lastUpdated: scoresList.lastUpdated, scores: scoresSeq)

proc invokeBoardsListCallback(boardsList: PDBoardsListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
    invokeCallback(privateBoardsListCallbacks, boardsList, errorMessage, playdate.scoreboards.freeBoardsList):
        let boardsSeq = boardsList.boards.items(boardsList.count).toSeq
            .mapIt(PDBoard(boardID: $it.boardID, name: $it.name))
        PDBoardsList(lastUpdated: boardsList.lastUpdated, boards: boardsSeq)

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
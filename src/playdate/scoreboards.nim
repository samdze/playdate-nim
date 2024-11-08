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

    PDResultKind* = enum 
        PDResultSuccess, 
        PDResultUnavailable,
            ## The operation completed successfully, but the response had no data
        PDResultError, 

    PDResult*[T] = object
        case kind*: PDResultKind
        of PDResultSuccess: result*: T
        of PDResultUnavailable: discard
        of PDResultError: message*: string

    PersonalBestCallback* = proc(result: PDResult[PDScore]) {.raises: [].}
    AddScoreCallback* = proc(result: PDResult[PDScore]) {.raises: [].}
    BoardsListCallback* = proc(result: PDResult[PDBoardsList]) {.raises: [].}
    ScoresCallback* = proc(result: PDResult[PDScoresList]) {.raises: [].}

var
    # The sdk callbacks unfortunately don't provide a userdata field to tag the callback with eg. the boardID
    # Scoreboard responses are handled in order of request, however, so if we keep track of request order everything should be fine.
    # By inserting the callback at the start, it will be popped last: first in, first out
    privatePersonalBestCallbacks = newSeq[PersonalBestCallback]()
    privateAddScoreCallbacks = newSeq[AddScoreCallback]()
    privateScoresCallbacks = newSeq[ScoresCallback]()
    privateBoardsListCallbacks = newSeq[BoardsListCallback]()

template invokeCallback(callbackSeqs, value, errorMessage, freeValue, builder: untyped) =
    type ResultType = typeof(builder)
    let callback = callbackSeqs.pop()
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
    ## Responds with PDResultUnavailable if no score exists for the current player.
    privateAccess(PlaydateScoreboards)
    privatePersonalBestCallbacks.insert(callback) # by inserting the callback at the start, it will be popped last: first in, first out
    return this.getPersonalBestBinding(boardID.cstring, invokePersonalBestCallback)

proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 {.discardable.} =
    ## Responds with PDResultUnavailable if the score was queued for later submission. Probably, Wi-Fi is not available.
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
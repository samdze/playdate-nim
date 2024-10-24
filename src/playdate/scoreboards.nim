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

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  let callback = privatePersonalBestCallbacks.pop() # first in, first out
  if score == nil and errorMessage == nil:
    callback(emptyPDScore, "Playdate-nim: No personal best")
    return

  if score == nil:
    callback(emptyPDScore, $errorMessage)
    return
    
  let domainScore = newPDScore(value = score.value.uint32, rank = score.rank.uint32, player = $score.player)
  playdate.scoreboards.freeScore(score)
  callback(domainScore, $errorMessage)

proc invokeAddScoreCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  let callback = privateAddScoreCallbacks.pop() # first in, first out
  if errorMessage != nil:
    callback(emptyPDScore, $errorMessage)
    return
    
  let domainScore = newPDScore(value = score.value.uint32, rank = score.rank.uint32, player = $score.player)
  playdate.scoreboards.freeScore(score)
  callback(domainScore, $errorMessage)

proc invokeScoresCallback(scoresList: PDScoresListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  privateAccess(PlaydateScoreboards)
  let callback = privateScoresCallbacks.pop() # first in, first out
  if scoresList == nil and errorMessage == nil:
    callback(emptyPDScoresList, "Playdate-nim: No scores")
    return

  if scoresList == nil:
    callback(emptyPDScoresList, $errorMessage)
    return

  privateAccess(SDKArray)
  let length = scoresList.count.cint
  let cArray = SDKArray[PDScoreRaw](data: cast[ptr UncheckedArray[PDScoreRaw]](scoresList.scores), len: length)
  var scoresSeq = newSeq[PDScore](length)
  for i in 0 ..< length:
    let score = cArray[i]
    scoresSeq[i] = newPDScore(value = score.value.uint32, rank = score.rank.uint32, player = $score.player)
  cArray.data = nil # no need for SDKArray to free the data, freeScoresList() will do it

  let domainObject = newPDScoresList(boardID = $scoresList.boardID, lastUpdated = scoresList.lastUpdated, scores = scoresSeq)
  callback(domainObject, $errorMessage)
  playdate.scoreboards.freeScoresList(scoresList)

proc invokeBoardsListCallback(boardsList: PDBoardsListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  let callback = privateBoardsListCallbacks.pop() # first in, first out
  if boardsList == nil and errorMessage == nil:
    callback(emptyPDBoardsList, "Playdate-nim: No boards")
    return

  if boardsList == nil:
    callback(emptyPDBoardsList, $errorMessage)
    return

  privateAccess(SDKArray)
  let length = boardsList.count.cint
  let cArray = SDKArray[PDBoardRaw](data: cast[ptr UncheckedArray[PDBoardRaw]](boardsList.boards), len: length)
  var boardsSeq = newSeq[PDBoard](length)
  for i in 0 ..< length:
    let board = cArray[i]
    boardsSeq[i] = newPDBoard(boardID = $board.boardID, name = $board.name)
  cArray.data = nil # no need for SDKArray to free the data, freeBoardsList() will do it

  let domainObject = newPDBoardsList(lastUpdated = boardsList.lastUpdated, boards = boardsSeq)

  callback(domainObject, $errorMessage)
  playdate.scoreboards.freeBoardsList(boardsList)

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
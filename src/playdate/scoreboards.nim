{.push raises: [].}

import std/importutils

import types {.all.}
import bindings/[api, types]
import bindings/scoreboards

# Only export public symbols, then import all
export scoreboards
{.hint[DuplicateModuleImport]: off.}
import bindings/scoreboards {.all.}

type PDScore* = object of RootObj
  value*: uint32
  rank*: uint32
  player*: string

type PDScoresList* = object of RootObj
  boardID*: string
  lastUpdated*: uint32
  scores*: seq[PDScore]
  # these properties are not implemented yet in the Playdate API
  # playerIncluded*: uint32
  # limit*: uint32

type
  PersonalBestCallback* = proc(score: PDScore, errorMessage: string)
  AddScoreCallback* = proc(score: PDScore, errorMessage: string)
  # BoardsListCallback* = proc(boards: ptr PDBoardsList, errorMessage: string)
  ScoresCallback* = proc(scores: PDScoresList, errorMessage: string)

var privatePersonalBestCallbacks = newSeq[PersonalBestCallback]()
var privateAddScoreCallback: AddScoreCallback
var privateScoresCallbacks = newSeq[ScoresCallback]()

proc newPDScore(value: uint32, rank: uint32, player: string): PDScore =
  result.value = value
  result.rank = rank
  result.player = player

proc newPDScoresList(boardID: string, lastUpdated: uint32, scores: seq[PDScore]): PDScoresList =
  result.boardID = boardID
  result.lastUpdated = lastUpdated
  result.scores = scores

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  let callback = privatePersonalBestCallbacks.pop() # first in, first out
  if score == nil and errorMessage == nil:
    callback(newPDScore(value = 0, rank = 0, player = ""), "Playdate-nim: No personal best")
    return

  if score == nil:
    callback(newPDScore(value = 0, rank = 0, player = ""), $errorMessage)
    return
    
  let domainScore = newPDScore(value = score.value.uint32, rank = score.rank.uint32, player = $score.player)
  playdate.scoreboards.freeScore(score)
  callback(domainScore, $errorMessage)

proc invokeAddScoreCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  if errorMessage != nil:
    privateAddScoreCallback(newPDScore(value = 0, rank = 0, player = ""), $errorMessage)
    return
    
  let domainScore = newPDScore(value = score.value.uint32, rank = score.rank.uint32, player = $score.player)
  playdate.scoreboards.freeScore(score)
  privateAddScoreCallback(domainScore, $errorMessage)

proc invokeScoresCallback(scoresList: PDScoresListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  privateAccess(PlaydateScoreboards)
  let callback = privateScoresCallbacks.pop() # first in, first out
  if scoresList == nil and errorMessage == nil:
    let domainObject = newPDScoresList(boardID = "", lastUpdated = 0, scores = @[])
    callback(domainObject, "Playdate-nim: No scores")
    return

  if scoresList == nil:
    let domainObject = newPDScoresList(boardID = "", lastUpdated = 0, scores = @[])
    callback(domainObject, $errorMessage)
    return

  privateAccess(SDKArray)
  let length = scoresList.count.cint
  let cArray = SDKArray[PDScoreRaw](data: cast[ptr UncheckedArray[PDScoreRaw]](scoresList.scores), len: length)
  var scoresSeq = newSeq[PDScore](length)
  for i in 0 ..< length:
    let score = cArray[i]
    scoresSeq[i] = PDScore(value: score.value.uint32, rank: score.rank.uint32, player: $score.player)
  cArray.data = nil # no need for SDKArray to free the data, freeScoresList() will do it

  let domainObject = newPDScoresList(boardID = $scoresList.boardID, lastUpdated = scoresList.lastUpdated, scores = scoresSeq)
  callback(domainObject, $errorMessage)
  playdate.scoreboards.freeScoresList(scoresList)

proc getPersonalBest*(this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privatePersonalBestCallbacks.insert(callback)
  return this.getPersonalBestBinding(boardID.cstring, invokePersonalBestCallback)

proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privateAddScoreCallback = callback
  return this.addScoreBinding(boardID.cstring, value.cuint, invokeAddScoreCallback)

# proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback): int32 =
#   privateAccess(PlaydateScoreboards)
# # proc freeBoardsList*(boardsList: ptr PDBoardsList) 
proc getScores*(this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privateScoresCallbacks.insert(callback)
  return this.getScoresBinding(boardID.cstring, invokeScoresCallback)
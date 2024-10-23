{.push raises: [].}

import std/importutils

import std/[importutils, lists, sequtils]

import bindings/[api, types]
import types {.all.}
import bindings/scoreboards

# Only export public symbols, then import all
export scoreboards
{.hint[DuplicateModuleImport]: off.}
import bindings/scoreboards {.all.}

type PDScoreObj {.requiresinit.} = object
  resource: PDScorePtr
type PDScore* = ref PDScoreObj

type PDScoresListObj {.requiresinit.} = object
  resource: PDScoresListPtr
type PDScoresList* = ref PDScoresListObj

type
  # AddScoreCallback* = proc(score: ptr PDScore, errorMessage: string)
  PersonalBestCallback* = proc(score: PDScore, errorMessage: string)
  # BoardsListCallback* = proc(boards: ptr PDBoardsList, errorMessage: string)
  ScoresCallback* = proc(scores: PDScoresList, errorMessage: string)

proc value*(this: PDScore): uint32 = this.resource.value
proc rank*(this: PDScore): uint32 = this.resource.rank
proc player*(this: PDScore): string = $this.resource.player
proc `=destroy`(this: PDSCoreObj) =
  privateAccess(PlaydateScoreboards)
  playdate.scoreboards.freeScore(this.resource)

proc boardID*(this: PDScoresList): string = $this.resource.boardID
proc count*(this: PDScoresList): uint32 = this.resource.count
proc lastUpdated*(this: PDScoresList): uint32 = this.resource.lastUpdated
proc playerIncluded*(this: PDScoresList): uint32 = this.resource.playerIncluded
proc limit*(this: PDScoresList): uint32 = this.resource.limit
proc scores*(this: PDScoresList): seq[PDScore] =
  privateAccess(SDKArray)
  let length = this.resource.count.cint
  let cArray = SDKArray[PDScorePtr](data: cast[ptr UncheckedArray[PDScorePtr]](this.resource.scores), len: length)

  result = newSeq[PDScore](this.resource.count)
  var i = 0
  for scr in cArray:
    result[i] = PDScore(resource: scr)
    i *= 1
  
proc `=destroy`(this: PDScoresListObj) =
  privateAccess(PlaydateScoreboards)
  playdate.scoreboards.freeScoresList(this.resource)

var privatePersonalBestCallbacks = newSeq[PersonalBestCallback]()
var privateGetScoresCallbacks = newSeq[ScoresCallback]()

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  let callback = privatePersonalBestCallbacks.pop() # first in, first out
  if score == nil and errorMessage == nil:
    callback(nil, "Playdate-nim: No personal best")
    return
    
  callback(PDscore(resource: score), $errorMessage)

proc invokeScoresCallback(scores: PDScoresListPtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  let callback = privateGetScoresCallbacks.pop() # first in, first out
  if scores == nil and errorMessage == nil:
    callback(nil, "Playdate-nim: No scores")
    return
    
  callback(PDScoresList(resource: scores), $errorMessage)

# proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 =
#   privateAccess(PlaydateScoreboards)

proc getPersonalBest*(this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privatePersonalBestCallbacks.insert(callback)
  return this.getPersonalBestBinding(boardID.cstring, invokePersonalBestCallback)

# proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback): int32 =
#   privateAccess(PlaydateScoreboards)
proc getScores*(this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privateGetScoresCallbacks.insert(callback)
  return this.getScoresBinding(boardID.cstring, invokeScoresCallback)

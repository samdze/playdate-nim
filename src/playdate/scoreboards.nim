{.push raises: [].}

import std/importutils

import system
import bindings/[api, types]
import bindings/scoreboards

# Only export public symbols, then import all
export scoreboards
{.hint[DuplicateModuleImport]: off.}
import bindings/scoreboards {.all.}

# type PDScoreObj = object of RootObj
#   # resource {.requiresinit.}: PDScorePtr
#   rank*: int32
#   value*: int32
#   player*: string

# proc `=destroy`(this: PDScoreObj) = 
#   privateaccess(PlaydateScoreboards)
#   playdate.scoreboards.freeScore(this.resource)
type PDScore* = object of RootObj
  value*: int32
  rank*: int32
  player*: string

type
  # AddScoreCallback* = proc(score: ptr PDScore, errorMessage: string)
  PersonalBestCallback* = proc(score: PDScore, errorMessage: string)
  # BoardsListCallback* = proc(boards: ptr PDBoardsList, errorMessage: string)
  # ScoresCallback* = proc(scores: ptr PDScoresList, errorMessage: string)

var privatePersonalBestCallback: PersonalBestCallback

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  if errorMessage != nil:
    privatePersonalBestCallback(PDScore(value: 0, rank: 0, player: ""), $errorMessage)
    return
    
  let domainScore = PDScore(value: score.value.int32, rank: score.rank.int32, player: $score.player)
  playdate.scoreboards.freeScore(score)
  privatePersonalBestCallback(domainScore, $errorMessage)

# proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 =
#   privateAccess(PlaydateScoreboards)

proc getPersonalBest*(this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privatePersonalBestCallback = callback
  return this.getPersonalBestBinding(boardID.cstring, invokePersonalBestCallback)

# proc freeScore*(score: ptr PDScore) 
# proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback): int32 =
#   privateAccess(PlaydateScoreboards)
# # proc freeBoardsList*(boardsList: ptr PDBoardsList) 
# proc getScores*(this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback): int32 =
#   privateAccess(PlaydateScoreboards)
# # proc freeScoresList*(scoresList: ptr PDScoresList) 
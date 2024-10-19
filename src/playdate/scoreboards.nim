{.push raises: [].}

import std/importutils

import system
import bindings/[api, types]
import bindings/scoreboards

# Only export public symbols, then import all
export scoreboards
{.hint[DuplicateModuleImport]: off.}
import bindings/scoreboards {.all.}

type
  # AddScoreCallback* = proc(score: ptr PDScore, errorMessage: string)
  PersonalBestCallback* = proc(score: PDScore, errorMessage: string)
  # BoardsListCallback* = proc(boards: ptr PDBoardsList, errorMessage: string)
  # ScoresCallback* = proc(scores: ptr PDScoresList, errorMessage: string)

var privatePersonalBestCallback: PersonalBestCallback

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: cstring) {.cdecl, raises: [].} =
  privatePersonalBestCallback(cast[PDScore](score), $errorMessage)

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
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
  AddScoreCallback* = proc(score: ptr PDScore, errorMessage: string)
  PersonalBestCallback* = proc(score: ptr PDScore, errorMessage: string)
  BoardsListCallback* = proc(boards: ptr PDBoardsList, errorMessage: string)
  ScoresCallback* = proc(scores: ptr PDScoresList, errorMessage: string)

proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 =
  privateAccess(PlaydateScoreboards)
proc getPersonalBest*(this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback): int32 =
  privateAccess(PlaydateScoreboards)

# proc freeScore*(score: ptr PDScore) 
proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback): int32 =
  privateAccess(PlaydateScoreboards)
# proc freeBoardsList*(boardsList: ptr PDBoardsList) 
proc getScores*(this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback): int32 =
  privateAccess(PlaydateScoreboards)
# proc freeScoresList*(scoresList: ptr PDScoresList) 
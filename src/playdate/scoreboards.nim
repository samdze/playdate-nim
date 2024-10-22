{.push raises: [].}

import std/importutils

import system
import bindings/[api, types]
import bindings/scoreboards

# Only export public symbols, then import all
export scoreboards
{.hint[DuplicateModuleImport]: off.}
import bindings/scoreboards {.all.}

type PDScoreObj {.requiresinit.} = object
  resource: PDScorePtr
type PDScore* = ref PDScoreObj

type
  # AddScoreCallback* = proc(score: ptr PDScore, errorMessage: string)
  PersonalBestCallback* = proc(score: PDScore, errorMessage: string)
  # BoardsListCallback* = proc(boards: ptr PDBoardsList, errorMessage: string)
  # ScoresCallback* = proc(scores: ptr PDScoresList, errorMessage: string)

proc value*(this: PDScore): uint32 = this.resource.value
proc rank*(this: PDScore): uint32 = this.resource.rank
proc player*(this: PDScore): string = $this.resource.player


proc `=destroy`(this: PDSCoreObj) =
  privateAccess(PlaydateScoreboards)
  playdate.scoreboards.freeScore(this.resource)

var privatePersonalBestCallback: PersonalBestCallback

proc invokePersonalBestCallback(score: PDScorePtr, errorMessage: ConstChar) {.cdecl, raises: [].} =
  if score == nil and errorMessage == nil:
    privatePersonalBestCallback(nil, "Playdate-nim: No personal best")
    return
    
  privatePersonalBestCallback(PDscore(resource: score), $errorMessage)

# proc addScore*(this: ptr PlaydateScoreboards, boardID: string, value: uint32, callback: AddScoreCallback): int32 =
#   privateAccess(PlaydateScoreboards)

proc getPersonalBest*(this: ptr PlaydateScoreboards, boardID: string, callback: PersonalBestCallback): int32 =
  privateAccess(PlaydateScoreboards)
  privatePersonalBestCallback = callback
  return this.getPersonalBestBinding(boardID.cstring, invokePersonalBestCallback)

# proc getScoreboards*(this: ptr PlaydateScoreboards, callback: BoardsListCallback): int32 =
#   privateAccess(PlaydateScoreboards)
# proc getScores*(this: ptr PlaydateScoreboards, boardID: string, callback: ScoresCallback): int32 =
#   privateAccess(PlaydateScoreboards)
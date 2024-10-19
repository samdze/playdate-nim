{.push raises: [].}

import utils

type PDScore* {.importc: "PDScore", header: "pd_api_scoreboards.h", bycopy.} = object
    rank* {.importc: "rank".}: uint32
    value* {.importc: "value".}: uint32
    player* {.importc: "player".}: cstring

type PDScoresList* {.importc: "PDScoresList", header: "pd_api_scoreboards.h", bycopy.} = object
    boardID* {.importc: "boardID".}: cstring
    count* {.importc: "count".}: cuint
    lastUpdated* {.importc: "lastUpdated".}: uint32
    playerIncluded* {.importc: "playerIncluded".}: cint
    limit* {.importc: "limit".}: cuint
    scores* {.importc: "scores".}: ptr PDScore

type PDBoard* {.importc: "PDBoard", header: "pd_api_scoreboards.h", bycopy.} = object
    boardID* {.importc: "boardID".}: cstring
    name* {.importc: "name".}: cstring

type PDBoardsList* {.importc: "PDBoardsList", header: "pd_api_scoreboards.h", bycopy.} = object
    count* {.importc: "count".}: cuint
    lastUpdated* {.importc: "lastUpdated".}: uint32
    boards* {.importc: "boards".}: ptr PDBoard

  # todo register free functions


type AddScoreCallbackRaw* = proc (score: ptr PDScore; errorMessage: cstring) {.cdecl.}
type PersonalBestCallbackRaw* = proc (score: ptr PDScore; errorMessage: cstring) {.cdecl.}
type BoardsListCallbackRaw* = proc (boards: ptr PDBoardsList; errorMessage: cstring) {.cdecl.}
type ScoresCallbackRaw* = proc (scores: ptr PDScoresList; errorMessage: cstring) {.cdecl.}

sdktype:
    type PlaydateScoreboards* {.importc: "const struct playdate_scoreboards", header: "pd_api.h".} = object
        addScore* {.importc: "addScore".}: proc (boardId: cstring; value: uint32;
            callback: AddScoreCallbackRaw): cint {.cdecl.}
        getPersonalBest* {.importc: "getPersonalBest".}: proc (boardId: cstring;
            callback: PersonalBestCallbackRaw): cint {.cdecl.}
        freeScore* {.importc: "freeScore".}: proc (score: ptr PDScore) {.cdecl.}
        getScoreboards* {.importc: "getScoreboards".}: proc (
            callback: BoardsListCallbackRaw): cint {.cdecl.}
        freeBoardsList* {.importc: "freeBoardsList".}: proc (
            boardsList: ptr PDBoardsList) {.cdecl.}
        getScores* {.importc: "getScores".}: proc (boardId: cstring;
            callback: ScoresCallbackRaw): cint {.cdecl.}
        freeScoresList* {.importc: "freeScoresList".}: proc (
            scoresList: ptr PDScoresList) {.cdecl.}
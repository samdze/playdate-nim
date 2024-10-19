{.push raises: [].}

import utils

type PDScoreRaw* {.importc: "PDScore", header: "pd_api.h", bycopy.} = object
    rank* {.importc: "rank".}: cuint
    value* {.importc: "value".}: cuint
    player* {.importc: "player".}: cstring

type PDScorePtr* = ptr PDScoreRaw
type PDScore* = ref PDScoreRaw

type PDScoresListRaw* {.importc: "PDScoresList", header: "pd_api.h", bycopy.} = object
    boardID* {.importc: "boardID".}: cstring
    count* {.importc: "count".}: cuint
    lastUpdated* {.importc: "lastUpdated".}: cuint
    playerIncluded* {.importc: "playerIncluded".}: cint
    limit* {.importc: "limit".}: cuint
    scores* {.importc: "scores".}: ptr PDScoreRaw

type PDBoardRaw* {.importc: "PDBoard", header: "pd_api.h", bycopy.} = object
    boardID* {.importc: "boardID".}: cstring
    name* {.importc: "name".}: cstring

type PDBoardsListRaw* {.importc: "PDBoardsList", header: "pd_api.h", bycopy.} = object
    count* {.importc: "count".}: cuint
    lastUpdated* {.importc: "lastUpdated".}: cuint
    boards* {.importc: "boards".}: ptr PDBoardRaw

  # todo register free functions


type PersonalBestCallbackRaw* {.importc: "PersonalBestCallback", header: "pd_api.h".} = proc (score: PDScorePtr; errorMessage: cstring) {.cdecl.}
# type AddScoreCallbackRaw* = proc (score: ptr PDScoreRaw; errorMessage: cstring) {.cdecl.}
# type BoardsListCallbackRaw* = proc (boards: ptr PDBoardsListRaw; errorMessage: cstring) {.cdecl.}
# type ScoresCallbackRaw* = proc (scores: ptr PDScoresListRaw; errorMessage: cstring) {.cdecl.}

sdktype:
    type PlaydateScoreboards* {.importc: "const struct playdate_scoreboards", header: "pd_api.h".} = object
        getPersonalBestBinding* {.importc: "getPersonalBest".}: proc (boardId: cstring;
            callback: PersonalBestCallbackRaw): cint {.cdecl, raises: [].}
        # addScore* {.importc: "addScore".}: proc (boardId: cstring; value: cuint;
        #     callback: AddScoreCallbackRaw): cint {.cdecl.}
        # freeScore* {.importc: "freeScore".}: proc (score: ptr PDScore) {.cdecl.}
        # getScoreboards* {.importc: "getScoreboards".}: proc (
        #     callback: BoardsListCallbackRaw): cint {.cdecl.}
        # freeBoardsList* {.importc: "freeBoardsList".}: proc (
        #     boardsList: ptr PDBoardsList) {.cdecl.}
        # getScores* {.importc: "getScores".}: proc (boardId: cstring;
        #     callback: ScoresCallbackRaw): cint {.cdecl.}
        # freeScoresList* {.importc: "freeScoresList".}: proc (
        #     scoresList: ptr PDScoresList) {.cdecl.}
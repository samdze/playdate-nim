{.push raises: [].}

import utils

type
    PDScoreRaw* {.importc: "PDScore", header: "pd_api.h", bycopy.} = object
        rank* {.importc: "rank".}: cuint
        value* {.importc: "value".}: cuint
        player* {.importc: "player".}: cstring

    PDScorePtr* = ptr PDScoreRaw

    PDScoresListRaw* {.importc: "PDScoresList", header: "pd_api.h", bycopy.} = object
        boardID* {.importc: "boardID".}: cstring
        count* {.importc: "count".}: cuint
        lastUpdated* {.importc: "lastUpdated".}: cuint
        playerIncluded* {.importc: "playerIncluded".}: cuint
        limit* {.importc: "limit".}: cuint
        scores* {.importc: "scores".}: ptr UncheckedArray[PDScoreRaw]

    PDScoresListPtr* = ptr PDScoresListRaw

    PDBoardRaw* {.importc: "PDBoard", header: "pd_api.h", bycopy.} = object
        boardID* {.importc: "boardID".}: cstring
        name* {.importc: "name".}: cstring

    PDBoardsListRaw* {.importc: "PDBoardsList", header: "pd_api.h", bycopy.} = object
        count* {.importc: "count".}: cuint
        lastUpdated* {.importc: "lastUpdated".}: cuint
        boards* {.importc: "boards".}: ptr UncheckedArray[PDBoardRaw]

    PDBoardsListPtr* = ptr PDBoardsListRaw

    PersonalBestCallbackRaw* {.importc: "PersonalBestCallback", header: "pd_api.h".} = proc (score: PDScorePtr; errorMessage: cstring) {.cdecl.}
    AddScoreCallbackRaw* {.importc: "AddScoreCallback", header: "pd_api.h".} = proc (score: PDScorePtr; errorMessage: cstring) {.cdecl.}
    BoardsListCallbackRaw* = proc (boards: ptr PDBoardsListRaw; errorMessage: cstring) {.cdecl.}
    ScoresCallbackRaw* = proc (scores: ptr PDScoresListRaw; errorMessage: cstring) {.cdecl.}

sdktype:
    type PlaydateScoreboards* {.importc: "const struct playdate_scoreboards", header: "pd_api.h".} = object
        getPersonalBestBinding* {.importc: "getPersonalBest".}: proc (boardId: cstring;
            callback: PersonalBestCallbackRaw): cint {.cdecl, raises: [].}
        addScoreBinding* {.importc: "addScore".}: proc (boardId: cstring; value: cuint;
            callback: AddScoreCallbackRaw): cint {.cdecl, raises: [].}
        freeScore* {.importc: "freeScore".}: proc (score: PDScorePtr) {.cdecl, raises: [].}
        getScoreboardsBinding* {.importc: "getScoreboards".}: proc (
            callback: BoardsListCallbackRaw): cint {.cdecl, raises: [].}
        freeBoardsList* {.importc: "freeBoardsList".}: proc (
            boardsList: PDBoardsListPtr) {.cdecl, raises: [].}
        getScoresBinding* {.importc: "getScores".}: proc (boardId: cstring;
            callback: ScoresCallbackRaw): cint {.cdecl, raises: [].}
        freeScoresList* {.importc: "freeScoresList".}: proc (
            scoresList: PDScoresListPtr) {.cdecl, raises: [].}
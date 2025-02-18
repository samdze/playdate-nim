{.push raises: [].}

import graphics, system, file, display, sprite, sound, scoreboards, lua

type PlaydateAPI* {.importc: "PlaydateAPI", header: "pd_api.h".} = object
    system* {.importc: "system".}: ptr PlaydateSys
    file* {.importc: "file".}: ptr PlaydateFile
    graphics* {.importc: "graphics".}: ptr PlaydateGraphics
    sprite* {.importc: "sprite".}: ptr PlaydateSprite
    display* {.importc: "display".}: ptr PlaydateDisplay
    sound* {.importc: "sound".}: ptr PlaydateSound
    scoreboards* {.importc: "scoreboards".}: ptr PlaydateScoreboards
    lua* {.importc: "lua".}: ptr PlaydateLua
    # json* {.importc: "json".}: ptr PlaydateJSON # Unavailable, use std/json

type PDSystemEvent* {.importc: "PDSystemEvent", header: "pd_api.h".} = enum
    kEventInit, kEventInitLua, kEventLock, kEventUnlock, kEventPause, kEventResume,
    kEventTerminate, kEventKeyPressed,
    kEventKeyReleased, kEventLowPower

var playdate*: ptr PlaydateAPI
export playdate
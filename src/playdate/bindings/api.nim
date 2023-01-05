{.push raises: [].}

import graphics, system, file, display, sprite, sound
# export graphics, system, file, display

type PlaydateAPI* {.importc: "PlaydateAPI", header: "pd_api.h".} = object
    system* {.importc: "system".}: PlaydateSys
    file* {.importc: "file".}: PlaydateFile
    graphics* {.importc: "graphics".}: PlaydateGraphics
    sprite* {.importc: "sprite".}: PlaydateSprite
    display* {.importc: "display".}: PlaydateDisplay
    sound* {.importc: "sound".}: ptr PlaydateSound

# type PlaydateAPI* = ptr PlaydateAPI
# template system*(this: PlaydateAPI): PlaydateSys = this.system
# template file*(this: PlaydateAPI): PlaydateFile = this.file
# template graphics*(this: PlaydateAPI): PlaydateGraphics = this.graphics
# template sprite*(this: PlaydateAPI): PlaydateSprite = this.sprite
# template display*(this: PlaydateAPI): PlaydateDisplay = this.display

type PDSystemEvent* {.importc: "PDSystemEvent", header: "pd_api.h".} = enum
    kEventInit, kEventInitLua, kEventLock, kEventUnlock, kEventPause, kEventResume,
    kEventTerminate, kEventKeyPressed,
    kEventKeyReleased, kEventLowPower

var playdate*: ptr PlaydateAPI
export playdate
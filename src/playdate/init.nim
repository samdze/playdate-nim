{.push raises: [].}

import library
export library

proc NimMain() {.importc.}

proc handler*(event: PDSystemEvent, keycode: uint)

proc eventHandler(api: ptr PlaydateAPI, event: PDSystemEvent, arg: uint32): cint {.cdecl, exportc.} =
    if event == kEventInit:
        NimMain()
        library.playdate = api
    handler(event, arg)
    return 0
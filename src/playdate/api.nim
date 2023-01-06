{.push raises: [].}

import macros

import library
export library

macro initSDK*() =
    return quote do:
        proc NimMain() {.importc.}

        proc eventHandler(api: ptr PlaydateAPI, event: PDSystemEvent, arg: uint32): cint {.cdecl, exportc.} =
            if event == kEventInit:
                NimMain()
                library.playdate = api
            handler(event, arg)
            return 0
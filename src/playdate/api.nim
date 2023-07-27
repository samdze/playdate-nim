{.push raises: [].}

import macros
import std/importutils

import bindings/utils {.all.} as memory
import bindings/api
export api

import graphics, system, file, sprite, display, sound, json, utils, types
export graphics, system, file, sprite, display, sound, json, utils, types

macro initSDK*() =
    return quote do:
        proc NimMain() {.importc.}

        proc eventHandler(playdateAPI: ptr PlaydateAPI, event: PDSystemEvent, arg: uint32): cint {.cdecl, exportc.} =
            privateAccess(PlaydateSys)
            if event == kEventInit:
                NimMain()
                api.playdate = playdateAPI
                memory.realloc = playdateAPI.system.realloc
            handler(event, arg)
            return 0

when not defined(simulator):
    proc fini() {.cdecl, exportc: "_fini".} =
        discard
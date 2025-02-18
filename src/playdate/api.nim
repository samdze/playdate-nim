{.push raises: [].}

import macros
import std/importutils, util/initreqs

import bindings/[api, initreqs]
export api

import graphics, system, file, sprite, display, sound, scoreboards, lua, json, utils, types, nineslice
export graphics, system, file, sprite, display, sound, scoreboards, lua, json, utils, types, nineslice

macro initSDK*() =
    return quote do:
        proc NimMain() {.importc.}

        proc eventHandler(playdateAPI: ptr PlaydateAPI, event: PDSystemEvent, arg: uint32): cint {.cdecl, exportc.} =
            privateAccess(PlaydateSys)
            privateAccess(PlaydateFile)
            if event == kEventInit:
                initPrereqs(playdateAPI.system.realloc, playdateAPI.system.logToConsole)
                NimMain()
                api.playdate = playdateAPI
            handler(event, arg)
            return 0

when not defined(simulator):
    proc fini() {.cdecl, exportc: "_fini".} =
        discard

when not defined(simulator) and defined(release):
    proc close(file: cint): cint {.cdecl, exportc: "_close".} =
        return -1

    proc fstat(file: cint, st: pointer): cint {.cdecl, exportc: "_fstat".} =
        return -1

    proc getpid(): cint {.cdecl, exportc: "_getpid".} =
        return 1

    proc isatty(file: cint): cint {.cdecl, exportc: "_isatty".} =
        return 0

    proc kill(pid, sig: cint): cint {.cdecl, exportc: "_kill".} =
        return 0

    proc lseek(file, pos, whence: cint): cint {.cdecl, exportc: "_lseek".} =
        return -1

    proc read(file: cint, pt: ptr cchar, len: cint): cint {.cdecl, exportc: "_read".} =
        return 0

    proc write(handle: cint, data: ptr cchar, size: cint): cint {.cdecl, exportc: "_write".} =
        return -1

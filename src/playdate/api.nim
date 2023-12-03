{.push raises: [].}

import macros
import std/importutils

import bindings/utils {.all.} as memory
import bindings/api
export api

import graphics, system, file, sprite, display, sound, lua, json, utils, types
export graphics, system, file, sprite, display, sound, lua, json, utils, types

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

# when not defined(simulator):
#     proc fini() {.cdecl, exportc: "_fini".} =
#         discard

# when not defined(simulator) and defined(release):
    # proc realloc_r(reent: pointer, aptr: pointer, bytes: csize_t): pointer {.cdecl, exportc: "_realloc_r".} =
    #     return nil

#     proc close(file: cint): cint {.cdecl, exportc: "_close".} =
#         return -1

#     proc fstat(file: cint, st: pointer): cint {.cdecl, exportc: "_fstat".} =
#         return -1

#     proc getpid(): cint {.cdecl, exportc: "_getpid".} =
#         return 1

#     proc isatty(file: cint): cint {.cdecl, exportc: "_isatty".} =
#         return 0

#     proc kill(pid, sig: cint): cint {.cdecl, exportc: "_kill".} =
#         return 0

#     proc lseek(file, pos, whence: cint): cint {.cdecl, exportc: "_lseek".} =
#         return -1

#     proc read(file: cint, pt: ptr cchar, len: cint): cint {.cdecl, exportc: "_read".} =
#         return 0

#     proc write(handle: cint, data: ptr cchar, size: cint): cint {.cdecl, exportc: "_write".} =
#         return -1
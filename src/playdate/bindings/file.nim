{.push raises: [].}

import utils

type SDFile* = pointer

type FileOptions* {.importc: "FileOptions", header: "pd_api.h".} = enum
    kFileRead = (1 shl 0), kFileReadData = (1 shl 1), kFileWrite = (1 shl 2),
    kFileAppend = (2 shl 2)

type FileStatRaw {.importc: "FileStat", header: "pd_api.h".} = object
    isdir* {.importc: "isdir".}: cint
    size* {.importc: "size".}: cuint
    mYear* {.importc: "m_year".}: cint
    mMonth* {.importc: "m_month".}: cint
    mDay* {.importc: "m_day".}: cint
    mHour* {.importc: "m_hour".}: cint
    mMinute* {.importc: "m_minute".}: cint
    mSecond* {.importc: "m_second".}: cint

type FileStatPtr = ptr FileStatRaw
type FileStat* = ref FileStatRaw

when not defined(SEEK_SET):
    const
        SEEK_SET* = 0
        SEEK_CUR* = 1
        SEEK_END* = 2

sdktype PlaydateFile:
    type PlaydateFile {.importc: "const struct playdate_file", header: "pd_api.h".} = object
        geterr {.importc: "geterr".}: proc (): cstring {.cdecl, raises: [].}
        listfilesRaw {.importc: "listfiles".}: proc (path: cstring;
            callback: proc (path: cstring; userdata: pointer) {.cdecl.}; userdata: pointer;
            showhidden: cint): cint {.cdecl, raises: [].}
        statRaw {.importc: "stat".}: proc (path: cstring; stat: FileStatPtr): cint {.cdecl, raises: [].}
        mkdirRaw {.importc: "mkdir".}: proc (path: cstring): cint {.cdecl, raises: [].}
        unlinkRaw {.importc: "unlink".}: proc (name: cstring; recursive: cint): cint {.cdecl, raises: [].}
        renameRaw {.importc: "rename".}: proc (`from`: cstring; to: cstring): cint {.cdecl, raises: [].}
        openRaw {.importc: "open".}: proc (name: cstring; mode: FileOptions): SDFile {.cdecl, raises: [].}
        closeRaw {.importc: "close".}: proc (file: SDFile): cint {.cdecl, raises: [].}
        readRaw {.importc: "read".}: proc (file: SDFile; buf: pointer; len: cuint): cint {.
            cdecl, raises: [].}
        writeRaw {.importc: "write".}: proc (file: SDFile; buf: pointer; len: cuint): cint {.
            cdecl, raises: [].}
        flushRaw {.importc: "flush".}: proc (file: SDFile): cint {.cdecl, raises: [].}
        tellRaw {.importc: "tell".}: proc (file: SDFile): cint {.cdecl, raises: [].}
        seekRaw {.importc: "seek".}: proc (file: SDFile; pos: cint; whence: cint): cint {.
            cdecl, raises: [].}
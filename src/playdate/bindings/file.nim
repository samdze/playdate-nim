{.push raises: [].}

import utils

type SDFilePtr = pointer

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

sdktype:
    type PlaydateFile* {.importc: "const struct playdate_file", header: "pd_api.h".} = object
        geterr {.importc: "geterr".}: proc (): cstring {.cdecl, raises: [].}
        listfiles {.importc: "listfiles".}: proc (path: cstring;
            callback: proc (path: cstring; userdata: pointer) {.cdecl.}; userdata: pointer;
            showhidden: cint): cint {.cdecl, raises: [].}
        stat {.importc: "stat".}: proc (path: cstring; stat: FileStatPtr): cint {.cdecl, raises: [].}
        mkdir {.importc: "mkdir".}: proc (path: cstring): cint {.cdecl, raises: [].}
        unlink {.importc: "unlink".}: proc (name: cstring; recursive: cint): cint {.cdecl, raises: [].}
        rename {.importc: "rename".}: proc (`from`: cstring; to: cstring): cint {.cdecl, raises: [].}
        open {.importc: "open".}: proc (name: cstring; mode: FileOptions): SDFilePtr {.cdecl, raises: [].}
        close {.importc: "close".}: proc (file: SDFilePtr): cint {.cdecl, raises: [].}
        read {.importc: "read".}: proc (file: SDFilePtr; buf: pointer; len: cuint): cint {.
            cdecl, raises: [].}
        write {.importc: "write".}: proc (file: SDFilePtr; buf: pointer; len: cuint): cint {.
            cdecl, raises: [].}
        flush {.importc: "flush".}: proc (file: SDFilePtr): cint {.cdecl, raises: [].}
        tell {.importc: "tell".}: proc (file: SDFilePtr): cint {.cdecl, raises: [].}
        seek {.importc: "seek".}: proc (file: SDFilePtr; pos: cint; whence: cint): cint {.
            cdecl, raises: [].}
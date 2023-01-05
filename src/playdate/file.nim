{.push raises: [].}

import std/importutils

import utils
import bindings/types
import bindings/file {.all.}
export file

proc fileCallback(filename: ConstChar, userdata: pointer) {.cdecl.} =
    var files = (cast[ptr seq[string]](userdata))
    files[].add($toC(filename))
    return

proc listFiles*(this: PlaydateFile, path: string, showHidden: bool = false): seq[string] {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var files = newSeq[string]()
    var res = this.listfilesRaw(toC(path.cstring), fileCallback, addr(files), if showHidden: 1 else: 0)
    if res != 0:
        raise newException(IOError, $this.geterr())
    return files

proc stat*(this: PlaydateFile, path: string): FileStat {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var info: FileStat = FileStat()
    let res = this.statRaw(path.cstring, addr(info[]))
    if res != 0:
        raise newException(IOError, $this.geterr())
    return info

proc unlink*(this: PlaydateFile, path: string, recursive: bool) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.unlinkRaw(path.cstring, if recursive: 1 else: 0)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc mkdir*(this: PlaydateFile, path: string) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.mkdirRaw(path.cstring)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc rename*(this: PlaydateFile, fromName: string, to: string) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.renameRaw(fromName.cstring, to.cstring)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc close*(this: PlaydateFile, file: SDFile) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.closeRaw(file)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc flush*(this: PlaydateFile, file: SDFile): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.flushRaw(file)
    if res < 0:
        raise newException(IOError, $this.geterr())
    return res

proc open*(this: PlaydateFile, path: string, mode: FileOptions): SDFile {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.openRaw(path.cstring, mode)
    if res == nil:
        raise newException(IOError, $this.geterr())
    return res

proc read*(this: PlaydateFile, file: SDFile, length: uint): (seq[byte], int) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var buffer = newSeq[byte](length)
    let res = this.readRaw(file, addr(buffer[0]), length.cuint)
    if res < 0:
        raise newException(IOError, $this.geterr())
    return (buffer, res.int)

proc seek*(this: PlaydateFile, file: SDFile, pos: int, whence: int) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.seekRaw(file, pos.cint, whence.cint)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc tell*(this: PlaydateFile, file: SDFile): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.tellRaw(file)
    if res < 0:
        raise newException(IOError, $this.geterr())
    return res

proc write*(this: PlaydateFile, file: SDFile, buffer: seq[byte], length: uint): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.writeRaw(file, unsafeAddr(buffer[0]), length.cuint)
    if res < 0:
        raise newException(IOError, $this.geterr())
    return res
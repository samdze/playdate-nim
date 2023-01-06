{.push raises: [].}

import std/importutils

import utils
import bindings/[api, types]
import bindings/file

# Only export public symbols, then import all
export file
{.hint[DuplicateModuleImport]: off.}
import bindings/file {.all.}

type
    SDFileObj {.requiresinit.} = object
        resource: SDFilePtr
    SDFile* = ref SDFileObj 

proc `=destroy`(this: var SDFileObj) =
    privateAccess(PlaydateFile)
    if this.resource != nil:
        discard playdate.file.close(this.resource)

proc fileCallback(filename: ConstChar, userdata: pointer) {.cdecl.} =
    var files = (cast[ptr seq[string]](userdata))
    files[].add($toC(filename))

proc listFiles*(this: ptr PlaydateFile, path: string, showHidden: bool = false): seq[string] {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var files = newSeq[string]()
    var res = this.listfiles(toC(path.cstring), fileCallback, addr(files), if showHidden: 1 else: 0)
    if res != 0:
        raise newException(IOError, $this.geterr())
    return files

proc stat*(this: ptr PlaydateFile, path: string): FileStat {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var info: FileStat = FileStat()
    let res = this.stat(path.cstring, addr(info[]))
    if res != 0:
        raise newException(IOError, $this.geterr())
    return info

proc unlink*(this: ptr PlaydateFile, path: string, recursive: bool) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.unlink(path.cstring, if recursive: 1 else: 0)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc mkdir*(this: ptr PlaydateFile, path: string) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.mkdir(path.cstring)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc rename*(this: ptr PlaydateFile, fromName: string, to: string) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.rename(fromName.cstring, to.cstring)
    if res != 0:
        raise newException(IOError, $this.geterr())

proc close*(this: SDFile) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = playdate.file.close(this.resource)
    if res != 0:
        raise newException(IOError, $playdate.file.geterr())

proc flush*(this: SDFile): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = playdate.file.flush(this.resource)
    if res < 0:
        raise newException(IOError, $playdate.file.geterr())
    return res

proc open*(this: ptr PlaydateFile, path: string, mode: FileOptions): SDFile {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = this.open(path.cstring, mode)
    if res == nil:
        raise newException(IOError, $this.geterr())
    return SDFile(resource: res)

proc read*(this: SDFile, length: uint): (seq[byte], int) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var buffer = newSeq[byte](length)
    let res = playdate.file.read(this.resource, addr(buffer[0]), length.cuint)
    if res < 0:
        raise newException(IOError, $playdate.file.geterr())
    return (buffer, res.int)

proc seek*(this: SDFile, pos: int, whence: int) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = playdate.file.seek(this.resource, pos.cint, whence.cint)
    if res != 0:
        raise newException(IOError, $playdate.file.geterr())

proc tell*(this: SDFile): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = playdate.file.tell(this.resource)
    if res < 0:
        raise newException(IOError, $playdate.file.geterr())
    return res

proc write*(this: SDFile, buffer: seq[byte], length: uint): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    let res = playdate.file.write(this.resource, unsafeAddr(buffer[0]), length.cuint)
    if res < 0:
        raise newException(IOError, $playdate.file.geterr())
    return res
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
        path: string
    SDFile* = ref SDFileObj

proc requireValidStatus(res: SomeInteger): int {.raises: [IOError], discardable.} =
    privateAccess(PlaydateFile)
    if res < 0:
        raise newException(IOError, $playdate.file.geterr())
    return res.int

proc requireNotNil[T: pointer](res: T): T {.raises: [IOError].} =
    privateAccess(PlaydateFile)
    if res == nil:
        raise newException(IOError, $playdate.file.geterr())
    return res

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
    this.listfiles(toC(path.cstring), fileCallback, addr(files), if showHidden: 1 else: 0).requireValidStatus
    return files

proc stat*(this: ptr PlaydateFile, path: string): FileStat {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var info: FileStat = FileStat()
    this.stat(path.cstring, addr(info[])).requireValidStatus
    return info

proc exists*(this: ptr PlaydateFile, path: string): bool =
    privateAccess(PlaydateFile)
    var info: FileStatRaw
    return this.stat(path.cstring, addr(info)) == 0

proc unlink*(this: ptr PlaydateFile, path: string, recursive: bool) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    this.unlink(path.cstring, if recursive: 1 else: 0).requireValidStatus

proc mkdir*(this: ptr PlaydateFile, path: string) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    this.mkdir(path.cstring).requireValidStatus

proc rename*(this: ptr PlaydateFile, fromName: string, to: string) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    this.rename(fromName.cstring, to.cstring).requireValidStatus

proc close*(this: SDFile) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    discard playdate.file.close(this.resource).requireValidStatus

proc flush*(this: SDFile): int {.raises: [IOError], discardable} =
    privateAccess(PlaydateFile)
    return playdate.file.flush(this.resource).requireValidStatus

proc open*(this: ptr PlaydateFile, path: string, mode: FileOptions): SDFile {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    return SDFile(resource: this.open(path.cstring, mode).requireNotNil, path: path)

proc read*(this: SDFile, length: uint): tuple[bytes: seq[byte], length: int] {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    var buffer = newSeq[byte](length)
    let res = playdate.file.read(this.resource, addr(buffer[0]), length.cuint).requireValidStatus
    return (bytes: buffer, length: res.int)

proc read*(this: SDFile): seq[byte] {.raises: [IOError]} =
    let size = playdate.file.stat(this.path).size
    privateAccess(PlaydateFile)
    var buffer = newSeq[byte](size)
    playdate.file.read(this.resource, addr(buffer[0]), size.cuint).requireValidStatus
    return buffer

proc readString*(this: SDFile): string {.raises: [IOError].} =
    let size = playdate.file.stat(this.path).size
    privateAccess(PlaydateFile)
    var str = newString(size)
    playdate.file.read(this.resource, addr(str[0]), size.cuint).requireValidStatus
    return str

proc seek*(this: SDFile, pos: int, whence: int) {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    playdate.file.seek(this.resource, pos.cint, whence.cint).requireValidStatus

proc tell*(this: SDFile): int {.raises: [IOError]} =
    privateAccess(PlaydateFile)
    return playdate.file.tell(this.resource).requireValidStatus

proc write*(this: SDFile, buffer: seq[byte], length: uint): int {.raises: [IOError], discardable} =
    privateAccess(PlaydateFile)
    if length > 0:
        return playdate.file.write(this.resource, unsafeAddr(buffer[0]), length.cuint).requireValidStatus

proc write*(this: SDFile, content: string): int {.raises: [IOError], discardable} =
    privateAccess(PlaydateFile)
    if content.len > 0:
        return playdate.file.write(this.resource, unsafeAddr(content[0]), content.len.cuint).requireValidStatus

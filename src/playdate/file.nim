{.push raises: [].}

import std/[importutils, streams]

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

  PDFileStreamObj = object of Stream
    file: SDFile

  PDFileStream = ref PDFileStreamObj

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

proc listFiles*(
    this: ptr PlaydateFile, path: string, showHidden: bool = false
): seq[string] {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  var files = newSeq[string]()
  this.listfiles(toC(path.cstring), fileCallback, addr(files), if showHidden: 1 else: 0).requireValidStatus
  return files

proc stat*(this: ptr PlaydateFile, path: string): FileStat {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  var info: FileStat = FileStat()
  this.stat(path.cstring, addr(info[])).requireValidStatus
  return info

proc exists*(this: ptr PlaydateFile, path: string): bool =
  privateAccess(PlaydateFile)
  var info: FileStatRaw
  return this.stat(path.cstring, addr(info)) == 0

proc unlink*(
    this: ptr PlaydateFile, path: string, recursive: bool
) {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  this.unlink(path.cstring, if recursive: 1 else: 0).requireValidStatus

proc mkdir*(this: ptr PlaydateFile, path: string) {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  this.mkdir(path.cstring).requireValidStatus

proc rename*(
    this: ptr PlaydateFile, fromName: string, to: string
) {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  this.rename(fromName.cstring, to.cstring).requireValidStatus

proc close*(this: SDFile) {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  discard playdate.file.close(this.resource).requireValidStatus

proc flush*(this: SDFile): int {.raises: [IOError], discardable.} =
  privateAccess(PlaydateFile)
  return playdate.file.flush(this.resource).requireValidStatus

proc open*(
    this: ptr PlaydateFile, path: string, mode: FileOptions
): SDFile {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  return SDFile(resource: this.open(path.cstring, mode).requireNotNil, path: path)

proc read*(
    this: SDFile, length: uint
): tuple[bytes: seq[byte], length: int] {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  var buffer = newSeq[byte](length)
  let res =
    playdate.file.read(this.resource, addr(buffer[0]), length.cuint).requireValidStatus
  return (bytes: buffer, length: res.int)

proc read*(this: SDFile): seq[byte] {.raises: [IOError].} =
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

proc seek*(this: SDFile, pos: int, whence: int) {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  playdate.file.seek(this.resource, pos.cint, whence.cint).requireValidStatus

proc tell*(this: SDFile): int {.raises: [IOError].} =
  privateAccess(PlaydateFile)
  return playdate.file.tell(this.resource).requireValidStatus

proc write*(
    this: SDFile, buffer: seq[byte], length: uint
): int {.raises: [IOError], discardable.} =
  privateAccess(PlaydateFile)
  if length > 0:
    return playdate.file.write(this.resource, unsafeAddr(buffer[0]), length.cuint).requireValidStatus

proc write*(this: SDFile, content: string): int {.raises: [IOError], discardable.} =
  privateAccess(PlaydateFile)
  if content.len > 0:
    return playdate.file.write(this.resource, unsafeAddr(content[0]), content.len.cuint).requireValidStatus

proc pdfsClose(s: Stream) {.raises: [IOError], tags: [WriteIOEffect], gcsafe.} =
  # Playdate files are auto-closed when they are destroyed
  discard

proc pdfsFlush(s: Stream) {.raises: [IOError], tags: [WriteIOEffect], gcsafe.} =
  {.cast(tags: []).}:
    discard PDFileStream(s).file.flush()

proc pdfsAtEnd(s: Stream): bool {.raises: [IOError], tags: [], gcsafe.} =
  let this = s.PDFileStream
  {.cast(tags: []).}:
    return this.file.tell() >= playdate.file.stat(this.file.path).size.int

proc pdfsGetPosition(s: Stream): int {.raises: [IOError], tags: [], gcsafe.} =
  {.cast(tags: []).}:
    return s.PDFileStream.file.tell()

proc pdfsSetPosition(s: Stream, pos: int) {.raises: [IOError], tags: [], gcsafe.} =
  {.cast(tags: []).}:
    s.PDFileStream.file.seek(pos, SEEK_SET)

proc pdfsReadData(
    s: Stream, buffer: pointer, bufLen: int
): int {.raises: [IOError], tags: [ReadIOEffect], gcsafe.} =
  privateAccess(PlaydateFile)
  {.cast(tags: []).}:
    if bufLen > 0:
      return playdate.file.read(s.PDFileStream.file.resource, buffer, bufLen.cuint).requireValidStatus

proc pdfsPeekData(
    s: Stream, buffer: pointer, bufLen: int
): int {.raises: [IOError], tags: [ReadIOEffect], gcsafe.} =
  {.cast(tags: []).}:
    let this = PDFileStream(s)
    let pos = this.file.tell()
    result = pdfsReadData(s, buffer, bufLen)
    this.file.seek(pos, SEEK_SET)

proc pdfsWriteData(
    s: Stream, buffer: pointer, bufLen: int
) {.raises: [IOError], tags: [WriteIOEffect], gcsafe.} =
  privateAccess(PlaydateFile)
  {.cast(tags: []).}:
    if bufLen > 0:
      discard
        playdate.file.write(s.PDFileStream.file.resource, buffer, bufLen.cuint).requireValidStatus

proc toStream*(this: SDFile): Stream {.raises: [].} =
  ## Wraps an open `SDFile` in a `std/streams` `Stream`, so it can be used
  ## with the generic stream reading/writing procs (`readLine`, `readAll`,
  ## `write`, `readInt32`, etc).
  return PDFileStream(
    file: this,
    closeImpl: pdfsClose,
    flushImpl: pdfsFlush,
    atEndImpl: pdfsAtEnd,
    getPositionImpl: pdfsGetPosition,
    setPositionImpl: pdfsSetPosition,
    readDataImpl: pdfsReadData,
    peekDataImpl: pdfsPeekData,
    writeDataImpl: pdfsWriteData,
  )

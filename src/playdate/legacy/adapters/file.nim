{.push raises: [].}

# import utils
import ../bindings/file
# export file

# proc fileCallback(filename: ConstChar, userdata: pointer) {.cdecl.}

proc listFiles*(this: PlaydateFile, path: string, showHidden: bool = false): seq[string] {.raises: [IOError]}

proc stat*(this: PlaydateFile, path: string): FileStat {.raises: [IOError]}

proc unlink*(this: PlaydateFile, path: string, recursive: bool) {.raises: [IOError]}

proc mkdir*(this: PlaydateFile, path: string) {.raises: [IOError]}

proc rename*(this: PlaydateFile, fromName: string, to: string) {.raises: [IOError]}

proc close*(this: PlaydateFile, file: SDFile) {.raises: [IOError]}

proc flush*(this: PlaydateFile, file: SDFile): int {.raises: [IOError]}

proc open*(this: PlaydateFile, path: string, mode: FileOptions): SDFile {.raises: [IOError]}

proc read*(this: PlaydateFile, file: SDFile, length: uint): (seq[byte], int) {.raises: [IOError]}

proc seek*(this: PlaydateFile, file: SDFile, pos: int, whence: int) {.raises: [IOError]}

proc tell*(this: PlaydateFile, file: SDFile): int {.raises: [IOError]}

proc write*(this: PlaydateFile, file: SDFile, buffer: seq[byte], length: uint): int {.raises: [IOError]}
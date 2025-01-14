import system/ansi_c, sparsemap, initreqs

proc mprotect(a1: pointer, a2: int, a3: cint): cint {.importc, header: "<sys/mman.h>".}

proc fopen(filename, mode: cstring): CFilePtr {.importc: "fopen", nodecl.}

proc fclose(file: CFilePtr) {.importc: "fclose", nodecl.}

const SLOTS = 20_000

const STACK_SIZE = 12

const BUFFER = sizeof(byte) * 8

type
    StackString[N : static int] = object
        data: array[N, char]
        len: int32

    StackFrame = object
        used: bool
        procname: StackString[50]
        filename: StackString[200]
        line: int32

    Allocation {.byref.} = object
        realPointer: pointer
        realSize: int32
        reported: bool
        resized: bool
        originalSize: int32
        protected: bool
        stack: array[STACK_SIZE, StackFrame]

    MemTrace* = object
        allocs: StaticSparseMap[SLOTS, uint64, Allocation]
        deleted: StaticSparseMap[SLOTS, uint64, Allocation]
        totalAllocs: int

proc toStackStr(input: cstring, N: static int): StackString[N] =
    var i = 0'i32
    for c in input:
        if i >= N - 1:
            break
        result.data[i] = c
        i += 1
    result.data[i] = '\0'
    result.len = i

proc endsWith(a, b: cstring): bool =
    false

proc createStackFrame[N: static int](frame: PFrame): array[N, StackFrame] =
    var current = frame
    var i = 0
    while i < N:
        if current == nil:
            break

        if not current.filename.endsWith("/arc.nim"):
            result[i] = StackFrame(
                used: true,
                procname: current.procname.toStackStr(50),
                filename: current.filename.toStackStr(200),
                line: current.line.int32
            )
            i += 1

        current = current.prev

proc printStack[N: static int](frames: array[N, StackFrame]) =
    for i in 0..<N:
        if not frames[i].used:
            return
        cfprintf(
            cstderr,
            "    %s:%i %s\n",
            addr frames[i].filename,
            frames[i].line,
            addr frames[i].procname
        )

proc printMem(p: pointer, size: Natural) =
    let data = cast[ptr UncheckedArray[byte]](p)
    for i in 0..<size:
        if i == BUFFER or i == size - BUFFER:
            cfprintf(cstderr, "\n ")

        let byt = data[i]
        if byt.int in 41..126:
            cfprintf(cstderr, " %c", byt)
        else:
            cfprintf(cstderr, " %X", byt.int)

    cfprintf(cstderr, "\n")

proc yesNo(flag: bool): char =
    return if flag: 'y' else: 'n'

proc print(alloc: Allocation, title: cstring, printMem: bool = false) =
    cfprintf(
        cstderr,
        "%s (resized: %c, original size: %i, fenced: %c)\n",
        title,
        alloc.resized.yesNo,
        alloc.originalSize,
        alloc.protected.yesNo,
    )
    cfprintf(
        cstderr,
        "  %p (Overall size: %i, internal size: %i)\n",
        alloc.realPointer,
        alloc.realSize,
        alloc.realSize - 2 * BUFFER
    )
    if printMem:
        alloc.realPointer.printMem(alloc.realSize)
    alloc.stack.printStack()

proc ord(p: pointer): auto = cast[uint64](p)

proc `+`(a: pointer, b: Natural): pointer = cast[pointer](cast[uint64](a) + b.uint64)

proc `-`(a: pointer, b: Natural): pointer = cast[pointer](cast[uint64](a) - b.uint64)

proc input(p: pointer): pointer = p - BUFFER

proc output(p: pointer): pointer = p + BUFFER

proc realSize(size: Natural): auto = size + BUFFER * 2

proc isInvalid(p: pointer, realSize: Natural): bool =
    let data = cast[ptr UncheckedArray[byte]](p)
    for i in 0..<BUFFER:
        if data[i] != 0 or data[realSize - 1 - i] != 0:
            return true
    return false

proc printPrior(trace: var MemTrace, p: pointer) =
    ## Returns the allocation just before the given allocation
    var distance = high(uint64)
    var found: Allocation
    let pInt = cast[uint64](p)
    for (_, alloc) in trace.allocs:
        let thisP = cast[uint64](alloc.realPointer)
        if pInt > thisP and pInt - thisP < distance:
            found = alloc
            distance = pInt - thisP

    if distance != high(uint64):
        found.print("Preceding allocation")
        cfprintf(cstderr, "  Distance: %i\n", distance)

proc check(trace: var MemTrace) =
    if trace.totalAllocs mod 100 == 0:
        cfprintf(cstderr, "Allocations count: %i (active: %i)\n", trace.totalAllocs, trace.allocs.size)

    for (_, alloc) in trace.allocs:
        if not alloc.protected and not alloc.reported and isInvalid(alloc.realPointer, alloc.realSize):
            alloc.reported = true
            alloc.print("CORRUPT! ")
            trace.printPrior(alloc.realPointer)

proc memRange(alloc: Allocation): Slice[uint64] =
    return cast[uint64](alloc.realPointer)..(cast[uint64](alloc.realPointer) + alloc.realSize.uint64)

proc checkOverlaps(trace: var MemTrace, title: cstring, newAlloc: Allocation) =
    let newRange = newAlloc.memRange
    for (_, alloc) in trace.allocs:
        let existingRange = alloc.memRange
        if existingRange.a in newRange or existingRange.b in newRange:
            cfprintf(cstderr, "%s overlaps with existing allocation!\n", title)
            newAlloc.print(title)
            alloc.print("Overlaps with:")

proc unprotect(p: pointer, size: Natural) =
    discard mprotect(p, BUFFER, 7)
    discard mprotect(p + size + BUFFER, BUFFER, 7)

proc protect(p: pointer, size: Natural): bool =
    if mprotect(p, BUFFER, 1) != 0:
        return false

    if mprotect(p + size + BUFFER, BUFFER, 1) != 0:
        discard mprotect(p, BUFFER, 7)
        return false

    return true

proc zeroBuffers(p: pointer, size: Natural) =
    zeroMem(p, BUFFER)
    zeroMem(p + size + BUFFER, BUFFER)
    if p.isInvalid(size.realSize):
        cfprintf(cstderr, "Zeroing failed! ")
        p.printMem(size.realSize)

proc record[N: static int](stack: array[N, StackFrame] = createStackFrame[N](getFrame())) {.inline.} =
    when defined(memrecord):
        let handle = fopen("memrecord.txt", "a")
        defer: fclose(handle)
        for i in 0..<N:
            if not stack[i].used:
                break
            if i > 0:
                c_fputc('|', handle)
            discard c_fwrite(addr stack[i].filename, 1, stack[i].filename.len.csize_t, handle)
            c_fputc(':', handle)
            discard c_fwrite(addr stack[i].procname, 1, stack[i].procname.len.csize_t, handle)
        c_fputc('\n', handle)

proc traceAlloc*(trace: var MemTrace, alloc: PDRealloc, size: Natural): pointer {.inline.} =
    trace.totalAllocs += 1
    trace.check

    let realPointer = alloc(nil, size.realSize.csize_t)
    result = realPointer.output

    zeroBuffers(realPointer, size)
    let protected = protect(realPointer, size)

    let entry = Allocation(
        realSize: size.realSize.int32,
        realPointer: realPointer,
        protected: protected,
        stack: createStackFrame[STACK_SIZE](getFrame()),
    )

    trace.checkOverlaps("New allocation", entry)

    trace.allocs[realPointer.ord] = entry

proc traceRealloc*(trace: var MemTrace, alloc: PDRealloc, p: pointer, newSize: Natural): pointer {.inline.} =
    record[5]()
    trace.check

    let realInPointer = p.input
    let origSize = trace.allocs[realInPointer.ord].realSize
    unprotect(realInPointer, origSize)

    let realOutPointer = alloc(realInPointer, newSize.realSize.csize_t)
    result = realOutPointer.output

    zeroBuffers(realOutPointer, newSize)
    let protected = protect(realOutPointer, newSize)

    trace.allocs.delete(realInPointer.ord)

    let entry = Allocation(
        realSize: newSize.realSize.int32,
        realPointer: realOutPointer,
        stack: createStackFrame[STACK_SIZE](getFrame()),
        resized: true,
        protected: protected,
        originalSize: origSize,
    )

    trace.checkOverlaps("Resized allocation", entry)

    trace.allocs[realOutPointer.ord] = entry

proc traceDealloc*(trace: var MemTrace, alloc: PDRealloc, p: pointer) {.inline.} =
    trace.check
    let realPointer = p.input
    if realPointer.ord notin trace.allocs:
        cfprintf(cstderr, "Attempting to dealloc unmanaged memory! %p\n", p)
        createStackFrame[STACK_SIZE](getFrame()).printStack()
        if realPointer.ord notin trace.deleted:
            trace.printPrior(p)
        else:
            trace.deleted[realPointer.ord].print("Previously deallocated", printMem = false)
        return
    else:
        var local = trace.allocs[realPointer.ord]
        local.stack = createStackFrame[STACK_SIZE](getFrame())

        unprotect(realPointer, local.realSize)
        discard alloc(realPointer, 0)
        trace.deleted[realPointer.ord] = local
        trace.allocs.delete(realPointer.ord)

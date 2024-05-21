##
## This file is a re-implementation of malloc.nim in the Nim standard library.It allows Nim itself to use the
## memory allocators provided by the playdate SDK.
##
## It works by by patching it in as a replacement in your configs.nim file, like this:
##
## ```nim
## patchFile("stdlib", "malloc", nimblePlaydatePath / "src/playdate/bindings/malloc")
## ```
##
## This patching is automatically configured when using `playdate/build/config`, as recommended by the setup
## documentation.
##

{.push stackTrace: off.}

when defined(memtrace):
    import system/ansi_c

# Forward declaration for memory profiling support
when defined(memProfiler):
    proc nimProfile(requestedSize: int)

type PDRealloc = proc (p: pointer; size: csize_t): pointer {.tags: [], raises: [], cdecl, gcsafe.}

var pdrealloc: PDRealloc

proc setupRealloc*(allocator: PDRealloc) =
    when defined(memtrace):
        cfprintf(cstderr, "Setting up playdate allocator")
    pdrealloc = allocator

proc allocImpl(size: Natural): pointer =
    when defined(memtrace):
        cfprintf(cstderr, "Allocating %d\n", size)

    # Integrage with: https://nim-lang.org/docs/estp.html
    when defined(memProfiler):
        {.cast(tags: []).}:
            try:
                nimProfile(size.int)
            except:
                discard

    result = pdrealloc(nil, size.csize_t)
    when defined(memtrace):
        cfprintf(cstderr, "  At %p\n", result)

proc alloc0Impl(size: Natural): pointer =
    result = allocImpl(size)
    zeroMem(result, size)

proc reallocImpl(p: pointer, newSize: Natural): pointer =
    when defined(memtrace):
        cfprintf(cstderr, "Reallocating %p with size %d\n", p, newSize)
    return pdrealloc(p, newSize.csize_t)

proc realloc0Impl(p: pointer, oldsize, newSize: Natural): pointer =
    result = reallocImpl(p, newSize.csize_t)
    if newSize > oldSize:
        zeroMem(cast[pointer](cast[uint](result) + uint(oldSize)), newSize - oldSize)

proc deallocImpl(p: pointer) =
    when defined(memtrace):
        cfprintf(cstderr, "Freeing %p\n", p)
    discard pdrealloc(p, 0)

# The shared allocators map on the regular ones

proc allocSharedImpl(size: Natural): pointer {.used.} = allocImpl(size)

proc allocShared0Impl(size: Natural): pointer {.used.} = alloc0Impl(size)

proc reallocSharedImpl(p: pointer, newSize: Natural): pointer {.used.} = reallocImpl(p, newSize)

proc reallocShared0Impl(p: pointer, oldsize, newSize: Natural): pointer {.used.} = realloc0Impl(p, oldSize, newSize)

proc deallocSharedImpl(p: pointer) {.used.} = deallocImpl(p)

proc getOccupiedMem(): int {.used.} = discard
proc getFreeMem(): int {.used.} = discard
proc getTotalMem(): int {.used.} = discard
proc deallocOsPages() {.used.} = discard

{.pop.}

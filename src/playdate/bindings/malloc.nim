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

when (compiles do:
    import playdate/util/initreqs):
    import playdate/util/initreqs
else:
    import ../util/initreqs

when defined(memProfiler):

    # Forward declaration for memory profiling support
    proc nimProfile(requestedSize: int)

    template rawAlloc(size): untyped =
        # Integrage with: https://nim-lang.org/docs/estp.html
        try:
            nimProfile(size.int)
        except:
            discard
        pdrealloc(nil, size)

    template rawRealloc(p, size): untyped = pdrealloc(p, size)
    template rawDealloc(p) = discard pdrealloc(p, 0)

elif defined(memtrace):
    import ../util/memtrace
    var trace: MemTrace

    template rawAlloc(size): untyped = traceAlloc(trace, pdrealloc, size)
    template rawRealloc(p, size): untyped = traceRealloc(trace, pdrealloc, p, size)
    template rawDealloc(p) = traceDealloc(trace, pdrealloc, p)

else:
    template rawAlloc(size): untyped = pdrealloc(nil, size)
    template rawRealloc(p, size): untyped = pdrealloc(p, size)
    template rawDealloc(p) = discard pdrealloc(p, 0)

proc allocImpl(size: Natural): pointer =
    {.cast(tags: []).}:
        return rawAlloc(size.csize_t)

proc alloc0Impl(size: Natural): pointer =
    result = allocImpl(size)
    zeroMem(result, size)

proc reallocImpl(p: pointer, newSize: Natural): pointer =
    {.cast(tags: []).}:
        return rawRealloc(p, newSize.csize_t)

proc realloc0Impl(p: pointer, oldsize, newSize: Natural): pointer =
    result = reallocImpl(p, newSize.csize_t)
    if newSize > oldSize:
        zeroMem(cast[pointer](cast[uint](result) + uint(oldSize)), newSize - oldSize)

proc deallocImpl(p: pointer) =
    {.cast(tags: []).}:
        rawDealloc(p)

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

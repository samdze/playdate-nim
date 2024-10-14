type
    Pair*[K, V] = tuple[key: K, value: V]

    Entry[K, V] = object
        pair: Pair[K, V]
        sparseIdx: uint32

    DenseIdx = distinct uint32

    StaticSparseMap*[N : static int, K, V] {.byref.} = object
        ## A sparse map implemented on the stack
        dense: array[N, Entry[K, V]]
        sparse: array[N, DenseIdx]
        size: uint32

const UnusedDenseIdx = DenseIdx(0)

const TombstonedIdx = DenseIdx(1)

proc toUInt(idx: DenseIdx): auto {.inline.} = uint32(idx) - 2

proc toDenseIdx(num: uint32): auto {.inline.} = DenseIdx(num + 2)

proc `==`(a, b: DenseIdx): bool {.inline.} = uint32(a) == uint32(b)

proc `=copy`[N : static int, K, V](a: var StaticSparseMap[N, K, V], b: StaticSparseMap[N, K, V]) {.error.}

proc size*[N : static int, K, V](m: var StaticSparseMap[N, K, V]): auto {.inline.} = m.size

iterator possibleSparseIdxs[N : static int, K](key: K): uint32 =
    ## Iterates through the possible indexes at which a key could be set
    let start = (ord(key).uint32 * 7) mod N.uint32
    for i in start..<N:
        yield i
    for i in 0'u32..<start:
        yield i

proc `[]=`*[N : static int, K, V](m: var StaticSparseMap[N, K, V], key: K, value: V) =
    ## Add an element into the map
    if m.size < N:
        for i in possibleSparseIdxs[N, K](key):
            let denseIdx = m.sparse[i]
            if denseIdx == UnusedDenseIdx or denseIdx == TombstonedIdx:
                m.dense[m.size] = Entry[K, V](pair: (key, value), sparseIdx: i)
                m.sparse[i] = m.size.toDenseIdx
                m.size.inc
                return

iterator items*[N : static int, K, V](m: var StaticSparseMap[N, K, V]): var Pair[K, V] =
    ## Iterates through all entries in this map
    for i in 0..<m.size:
        yield m.dense[i].pair

template find[N, K, V](m: var StaticSparseMap[N, K, V], key: K, exec: untyped): untyped =
    for sparseIdx {.inject.} in possibleSparseIdxs[N, K](key):
        let denseIdx {.inject.} = m.sparse[sparseIdx]

        if denseIdx == UnusedDenseIdx:
            break
        elif not(denseIdx == TombstonedIdx):
            var entry {.inject.} = m.dense[denseIdx.toUInt]
            if entry.pair.key == key:
                exec

proc contains*[N : static int, K, V](m: var StaticSparseMap[N, K, V], key: K): bool =
    ## Whethera key is in this table
    m.find(key):
        return true
    return false

proc `[]`*[N : static int, K, V](m: var StaticSparseMap[N, K, V], key: K): V =
    ## Get a pointer to a key in this map
    m.find(key):
        return entry.pair.value

proc delete*[N : static int, K, V](m: var StaticSparseMap[N, K, V], key: K) =
    ## Remove a key and its value from this map
    if m.size > 0:
        m.find(key):

            # Invalidate the existing index
            m.sparse[sparseIdx] = TombstonedIdx

            # Reduce the total number of stored values
            m.size.dec

            # If the dense index is already at the end of the list, we just need to clear it
            if denseIdx.toUInt == m.size:
                m.dense[m.size] = Entry[K, V]()

            else:
                # Move the last dense value to ensure everything is tightly packed
                m.dense[denseIdx.toUInt] = move(m.dense[m.size])

                # Updated the sparse index of the moved value to point to its new location
                m.sparse[m.dense[denseIdx.toUInt].sparseIdx] = denseIdx

            return

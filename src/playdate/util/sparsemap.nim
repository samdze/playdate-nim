type
    Pair*[K, V] = tuple[key: K, value: V]

    Entry[K, V] = object
        pair: Pair[K, V]
        sparseIdx: int32

    StaticSparseMap*[N : static int, K, V] {.byref.} = object
        ## A sparse map implemented on the stack
        dense: array[N, Entry[K, V]]
        sparse: array[N, int32]
        size: int32

proc `=copy`[N : static int, K, V](a: var StaticSparseMap[N, K, V], b: StaticSparseMap[N, K, V]) {.error.}

proc size*[N : static int, K, V](m: var StaticSparseMap[N, K, V]): auto {.inline.} = m.size

proc bestIndex[N : static int, K](key: K): int32 {.inline.} =
    ## Returns the best index a key can be at for a given key
    (ord(key).int32 * 7) mod (N).int32

iterator possibleSparseIdxs[N : static int, K](key: K): int32 =
    ## Iterates through the possible indexes at which a key could be set
    let start = bestIndex[N, K](key)
    for i in start..<N:
        yield i
    for i in 0'i32..<start:
        yield i

proc `[]=`*[N : static int, K, V](m: var StaticSparseMap[N, K, V], key: K, value: sink V) =
    ## Add an element into the map
    if m.size < N:
        for i in possibleSparseIdxs[N, K](key):
            let denseIdx = m.sparse[i]
            if denseIdx >= m.size or m.dense[denseIdx].sparseIdx != i:
                m.dense[m.size] = Entry[K, V](pair: (key, value), sparseIdx: i)
                m.sparse[i] = m.size
                m.size.inc
                return

iterator items*[N : static int, K, V](m: var StaticSparseMap[N, K, V]): var Pair[K, V] =
    ## Iterates through all entries in this map
    for i in 0..<m.size:
        yield m.dense[i].pair

template find[N, K, V](m: StaticSparseMap[N, K, V], key: sink K, exec: untyped): untyped =
    for sparseIdx {.inject.} in possibleSparseIdxs[N, K](key):
        let denseIdx {.inject.} = m.sparse[sparseIdx]
        if denseIdx >= m.size:
            break
        var entry {.inject.} = m.dense[denseIdx]
        if entry.sparseIdx != sparseIdx:
            break
        elif entry.pair.key == key:
            exec

proc `[]`*[N : static int, K, V](m: StaticSparseMap[N, K, V], key: sink K): ptr V =
    ## Get a pointer to a key in this map
    m.find(key):
        return addr entry.pair.value

proc delete*[N : static int, K, V](m: var StaticSparseMap[N, K, V], key: sink K) =
    ## Remove a key and its value from this map
    if m.size > 0:
        m.find(key):
            m.size.dec
            swap(m.dense[denseIdx], m.dense[m.size])
            m.sparse[m.dense[denseIdx].sparseIdx] = denseIdx
            m.dense[m.size] = Entry[K, V]()

import unittest, random, algorithm, sequtils, playdate/util/sparsemap {.all.}, strutils, tables

iterator allPermutations[T](input: openarray[T]): seq[T] =
    var input = input.toSeq
    yield input
    while input.nextPermutation():
        yield input

proc randomData[T](N: int, maxVal: T): seq[T] =
    result = newSeq[T](N)
    for i in 0 ..< N:
        result[i] = rand(maxVal-1)

randomize(123)

proc expectData[N : static int](map: var StaticSparseMap[N, int, string], expect: openarray[int]) =
    require(map.toSeq.mapIt(it.key).sorted() == expect.toSeq.sorted())
    require(map.toSeq.mapIt(it.value).sorted() == expect.toSeq.mapIt($it).sorted())

    for key in expect:
        checkpoint("Checking key " & $key)
        require(key in map)
        require(map[key] == $key)

    for key in 5000..5100:
        require(key notin map)

proc compareTables(map: var StaticSparseMap, expect: Table) =
    for key, value in expect:
        require(key in map)
        require(map[key] == value)

    for (key, value) in map:
        require(key in expect)
        require(expect[key] == value)

    require(map.size.int == expect.len)

suite "StaticSparseMap":

    test "All possible sparse index keys should be covered":
        proc visitAllKeys[N: static int](startKey: int32) =
            var visitedKeys = newSeq[uint32]()
            for key in possibleSparseIdxs[N, int32](startKey):
                visitedKeys.add key
            visitedKeys.sort
            require(visitedKeys == toSeq(0'u32..<N.uint32))

        visitAllKeys[10](20)
        visitAllKeys[100](50)

    for size in [0, 1, 10, 100]:
        test "Setting of size " & $size:
            var m: StaticSparseMap[200, int, string]

            let data = randomData(size, 500)

            for value in data:
                m[value] = $value

            expectData[200](m, data)

    test "Adding more data than capacity":
        var m: StaticSparseMap[5, int, string]
        let data = randomData(5, 100)
        for value in data:
            m[value] = $value

        m[400] = "ignored"
        m[500] = "also ignored"

        expectData[5](m, data)

    for keys in allPermutations(toSeq(0..3)):
        test "Deleting keys in order " & $keys:
            var m: StaticSparseMap[5, int, string]
            for i in keys:
                m[i] = $i

            for i, key in keys:
                require(key in m)
                m.delete(key)
                require(key notin m)
                m.expectData(keys[(i+1)..<keys.len])

            m.delete(500)
            expectData(m, [])

    test "Bulk operations":
        var compare = initTable[int64, int](3_000)
        var m: StaticSparseMap[3_000, int64, int]
        for line in lines("tests/sparsemap_ops.txt"):
            let parts = split(line, ',')
            let removeKey = fromHex[int64](parts[1])
            let setKey = fromHex[int64](parts[2])
            let value = parseInt(parts[3])
            checkpoint ${ "action": parts[0], "removeKey": $removeKey, "setKey": $setKey, "value": $value }
            case parts[0]
            of "alloc":
                require(setKey == removeKey)
                require(setKey notin m)
                m[setKey] = value
                compare[setKey] = value
                require(setKey in m)
                require(m[setKey] == value)
            of "dealloc":
                require(setKey == removeKey)
                require(removeKey in m)
                m.delete(removeKey)
                compare.del(removeKey)
                require(setKey notin m)
            of "realloc":
                require(removeKey in m)
                m.delete(removeKey)
                compare.del(removeKey)
                require(setKey notin m)
                m[setKey] = value
                compare[setKey] = value
                require(setKey in m)
                require(m[setKey] == value)
            else:
                require(false)

            compareTables(m, compare)

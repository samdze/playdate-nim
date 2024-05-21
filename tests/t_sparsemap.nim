import unittest, random, algorithm, sequtils, playdate/bindings/sparsemap

proc randomData[T](N: int, maxVal: T): seq[T] =
    result = newSeq[T](N)
    for i in 0 ..< N:
        result[i] = rand(maxVal-1)

randomize(123)

proc expectData[N : static int](map: var StaticSparseMap[N, int, string], expect: openarray[int]) =
    check(map.toSeq.mapIt(it.key).sorted() == expect.toSeq.sorted())
    check(map.toSeq.mapIt(it.value).sorted() == expect.toSeq.mapIt($it).sorted())

    for key in expect:
        checkpoint("Checking key " & $key)
        check(map[key] != nil)
        if map[key] != nil:
            check(map[key][] == $key)

    for key in 5000..5100:
        check(map[key] == nil)

suite "StaticSparseMap":

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

    test "Deleting values":
        var m: StaticSparseMap[10, int, string]
        for i in 0..5:
            m[i] = $i

        m.delete(3)
        expectData[10](m, [0, 1, 2, 4, 5])

        m.delete(0)
        expectData[10](m, [1, 2, 4, 5])

        m.delete(4)
        expectData[10](m, [1, 2, 5])

        m.delete(2)
        expectData[10](m, [1, 5])

        m.delete(1)
        expectData[10](m, [5])

        m.delete(5)
        expectData[10](m, [])

        m.delete(500)
        expectData[10](m, [])
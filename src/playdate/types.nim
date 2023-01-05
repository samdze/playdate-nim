import bindings/utils

type SDKArrayObj[T] = object
    len: int
    data: ptr UncheckedArray[T]
type SDKArray*[T] = ref SDKArrayObj[T]

proc `=destroy`*[T](this: var SDKArrayObj[T]) =
    if this.data != nil:
        discard utils.realloc(this.data, 0)

proc `[]`*[T](this: SDKArray[T]; i: Natural): lent T =
    assert i < this.len
    this.data[i]

proc `[]=`*[T](this: var SDKArray[T]; i: Natural; y: sink T) =
    assert i < this.len
    this.data[i] = y

proc len*[T](this: SDKArray[T]): int {.inline.} = this.len

iterator items*[T](this: SDKArray[T]): lent T {.inline.} =
    var i = 0
    while i < len(this):
        yield this[i]
        inc(i)

iterator mitems*[T](this: var SDKArray[T]): var T {.inline.} =
    var i = 0
    while i < len(this):
        yield this[i]
        inc(i)

iterator pairs*[T](this: SDKArray[T]): tuple[key: int, val: T] {.inline.} =
    var i = 0
    while i < len(this):
        yield (i, this[i])
        inc(i)

iterator mpairs*[T](this: var SDKArray[T]): tuple[key: int, val: var T] {.inline.} =
    var i = 0
    while i < len(this):
        yield (i, this[i])
        inc(i)
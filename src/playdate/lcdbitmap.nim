import std/importutils
import bindings/[api, types, graphics]

type
    LCDBitmapObj = object of RootObj
        res {.requiresinit.}: LCDBitmapPtr

    LCDBitmapObjRef = ref LCDBitmapObj

    LCDBitmap* = object
        case managed: bool
        of true:
            obj: LCDBitmapObjRef
        of false:
            res: LCDBitmapPtr

proc `=destroy`(this: var LCDBitmapObj) =
    privateAccess(PlaydateGraphics)
    if this.res != nil:
        playdate.graphics.freeBitmap(this.res)

proc `=copy`(a: var LCDBitmapObj, b: LCDBitmapObj) {.error.}

converter bitmapPtr*(point: LCDBitmapPtr): auto =
    LCDBitmap(managed: false, res: point)

proc bitmapRef(point: LCDBitmapPtr): auto =
    LCDBitmap(managed: true, obj: LCDBitmapObjRef(res: point))

proc `==`*(bitmap: LCDBitmap, point: LCDBitmapPtr): bool =
    not bitmap.managed and bitmap.res == point

proc resource(bitmap: LCDBitmap): LCDBitmapPtr =
    if bitmap.managed:
        return if bitmap.obj != nil: bitmap.obj.res else: nil
    else:
        return bitmap.res

proc isNil*(bitmap: LCDBitmap): bool =
    return bitmap.resource == nil
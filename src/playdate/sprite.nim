{.push raises: [].}

import std/[importutils, lists, sequtils]

import graphics {.all.}
import types {.all.}
import bindings/[api, utils]
import bindings/sprite

# Only export public symbols, then import all
export sprite
{.hint[DuplicateModuleImport]: off.}
import bindings/sprite {.all.}

type
    LCDSpriteObj = object
        resource {.requiresinit.}: LCDSpritePtr
        bitmap: LCDBitmap # Resource the sprite has to keep in memory
        stencil: LCDBitmap # Resource the sprite has to keep in memory
        collisionFunction: LCDSpriteCollisionFilterProc
        drawFunction: LCDSpriteDrawFunction
        updateFunction: LCDSpriteUpdateFunction
    LCDSprite* = ref LCDSpriteObj

    LCDSpriteCollisionFilterProc* = proc(sprite: LCDSprite, other: LCDSprite): SpriteCollisionResponseType {.closure, raises: [].}
    LCDSpriteDrawFunction* = proc (sprite: LCDSprite; bounds: PDRect; drawRect: PDRect) {.closure, raises: [].}
    LCDSpriteUpdateFunction* = proc (sprite: LCDSprite) {.closure, raises: [].}

proc `=destroy`(this: var LCDSpriteObj) =
    privateAccess(PlaydateSprite)
    playdate.sprite.freeSprite(this.resource)
    this.collisionFunction = nil
    this.drawFunction = nil
    this.updateFunction = nil
    `=destroy`(this.bitmap)
    `=destroy`(this.stencil)

var spritesData = initDoublyLinkedList[LCDSprite]()

proc setAlwaysRedraw*(this: ptr PlaydateSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    this.setAlwaysRedraw(if flag: 1 else: 0)

proc moveTo*(this: LCDSprite, x: cfloat, y: cfloat) =
    privateAccess(PlaydateSprite)
    playdate.sprite.moveTo(this.resource, x, y)

proc moveBy*(this: LCDSprite, x: cfloat, y: cfloat) =
    privateAccess(PlaydateSprite)
    playdate.sprite.moveBy(this.resource, x, y)

# Sprites memory managament
proc newSprite*(this: ptr PlaydateSprite): LCDSprite =
    privateAccess(PlaydateSprite)
    let spritePtr = this.newSprite()
    return LCDSprite(resource: spritePtr)

proc copy*(this: LCDSprite): LCDSprite =
    privateAccess(PlaydateSprite)
    let newSpritePtr = playdate.sprite.copy(this.resource)
    return LCDSprite(resource: newSpritePtr, bitmap: this.bitmap, stencil: this.stencil)

proc add*(this: LCDSprite) =
    privateAccess(PlaydateSprite)
    if playdate.sprite.getUserdata(this.resource) != nil:
        return
    playdate.sprite.addSprite(this.resource)
    let dataNode = newDoublyLinkedNode[LCDSprite](this)
    spritesData.add(dataNode)
    # let tailAddr = addr(spritesData.tail)
    # playdate.system.logToConsole(fmt"tail addr is {tailAddr.repr}")
    playdate.sprite.setUserdata(this.resource, addr(dataNode[]))

proc remove*(this: LCDSprite) =
    privateAccess(PlaydateSprite)
    let dataNode = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(this.resource))
    if dataNode == nil:
        return
    playdate.sprite.removeSprite(this.resource)
    if dataNode.prev != nil:
        spritesData.remove(dataNode.prev.next)
    else:
        spritesData.remove(spritesData.head)
    # spritesData.remove(dataNode[])
    playdate.sprite.setUserdata(this.resource, nil)

proc removeSprites*(this: ptr PlaydateSprite, sprites: seq[LCDSprite]) =
    privateAccess(PlaydateSprite)
    let spritePointers = sprites.map(proc(s: LCDSprite): LCDSpritePtr = return s.resource)
    this.removeSprites(cast[ptr LCDSpritePtr](unsafeAddr(spritePointers[0])), spritePointers.len.cint)
    for i, s in sprites:
        let dataNode = cast[ptr DoublyLinkedNodeObj[LCDSprite]](this.getUserdata(s.resource))
        if dataNode == nil:
            return
        if dataNode.prev != nil:
            spritesData.remove(dataNode.prev.next)
        else:
            spritesData.remove(spritesData.head)
        # spritesData.remove(dataNode[])
        this.setUserdata(s.resource, nil)

proc removeAllSprites*(this: ptr PlaydateSprite) =
    privateAccess(PlaydateSprite)
    this.removeAllSprites()
    for s in spritesData.mitems:
        this.setUserdata(s.resource, nil)
    spritesData = initDoublyLinkedList[LCDSprite]()

proc `bounds=`*(this: LCDSprite, bounds: PDRect) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setBounds(this.resource, bounds)

proc bounds*(this: LCDSprite): PDRect =
    privateAccess(PlaydateSprite)
    return playdate.sprite.getBounds(this.resource)

proc setImage*(this: LCDSprite, image: LCDBitmap, flip: LCDBitmapFlip) =
    privateAccess(PlaydateSprite)
    privateAccess(LCDBitmap)
    playdate.sprite.setImage(this.resource, if image != nil: image.resource else: nil, flip)
    this.bitmap = image

proc getImage*(this: LCDSprite): LCDBitmap =
    privateAccess(PlaydateSprite)
    return this.bitmap

proc setSize*(this: LCDSprite, width: float32, height: float32) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setSize(this.resource, width.cfloat, height.cfloat)

proc `zIndex=`*(this: LCDSprite, zIndex: int16) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setZIndex(this.resource, zIndex)

proc zIndex*(this: LCDSprite): int16 =
    privateAccess(PlaydateSprite)
    return playdate.sprite.getZIndex(this.resource)

proc setDrawMode*(this: LCDSprite, mode: LCDBitmapDrawMode) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setDrawMode(this.resource, mode)

proc `imageFlip=`*(this: LCDSprite, flip: LCDBitmapFlip) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setImageFlip(this.resource, flip)

proc imageFlip*(this: LCDSprite): LCDBitmapFlip =
    privateAccess(PlaydateSprite)
    return playdate.sprite.getImageFlip(this.resource)

proc setClipRect*(this: LCDSprite, clipRect: LCDRect) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setClipRect(this.resource, clipRect)

proc clearClipRect*(this: LCDSprite) =
    privateAccess(PlaydateSprite)
    playdate.sprite.clearClipRect(this.resource)

proc setClipRectsInRange*(clipRect: LCDRect, startZ: int, endZ: int) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setClipRectsInRange(clipRect, startZ.cint, endZ.cint)

proc clearClipRectsInRange*(startZ: int, endZ: int)=
    privateAccess(PlaydateSprite)
    playdate.sprite.clearClipRectsInRange(startZ.cint, endZ.cint)

proc `updatesEnabled=`*(this: LCDSprite, enabled: bool) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setUpdatesEnabled(this.resource, if enabled: 1 else: 0)

proc updatesEnabled*(this: LCDSprite): bool =
    privateAccess(PlaydateSprite)
    return playdate.sprite.updatesEnabled(this.resource) > 0

proc `collisionsEnabled=`*(this: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setCollisionsEnabled(this.resource, if flag: 1 else: 0)

proc collisionsEnabled*(this: LCDSprite): bool =
    privateAccess(PlaydateSprite)
    return playdate.sprite.collisionsEnabled(this.resource) == 1

proc `visible=`*(this: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setVisible(this.resource, if flag: 1 else: 0)

proc visible*(this: LCDSprite): bool =
    privateAccess(PlaydateSprite)
    return playdate.sprite.isVisible(this.resource) == 1

proc setOpaque*(this: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setOpaque(this.resource, if flag: 1 else: 0)

proc markDirty*(this: LCDSprite) =
    privateAccess(PlaydateSprite)
    playdate.sprite.markDirty(this.resource)

proc `tag=`*(this: LCDSprite, tag: uint8) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setTag(this.resource, tag)

proc tag*(this: LCDSprite): uint8 =
    privateAccess(PlaydateSprite)
    return playdate.sprite.getTag(this.resource)

proc setIgnoresDrawOffset*(this: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setIgnoresDrawOffset(this.resource, if flag: 1 else: 0)

# --- Update function.
proc privateUpdateFunction(sprite: LCDSpritePtr) {.cdecl, exportc, raises: [].} =
    privateAccess(PlaydateSprite)
    let spriteRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(sprite)).value
    spriteRef.updateFunction(spriteRef)

proc setUpdateFunction*(this: LCDSprite, update: LCDSpriteUpdateFunction) =
    privateAccess(PlaydateSprite)
    this.updateFunction = update
    playdate.sprite.setUpdateFunction(this.resource, if update != nil: privateUpdateFunction else: nil)

# --- Draw function.
proc privateDrawFunction(sprite: LCDSpritePtr, bounds: PDRect, drawRect: PDRect) {.cdecl, exportc, raises: [].} =
    privateAccess(PlaydateSprite)
    let spriteRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(sprite)).value
    spriteRef.drawFunction(spriteRef, bounds, drawRect)

proc setDrawFunction*(this: LCDSprite, draw: LCDSpriteDrawFunction) =
    privateAccess(PlaydateSprite)
    this.drawFunction = draw
    playdate.sprite.setDrawFunction(this.resource, if draw != nil: privateDrawFunction else: nil)




proc getPosition*(this: LCDSprite): tuple[x: float32, y: float32] =
    privateAccess(PlaydateSprite)
    var x, y: cfloat
    playdate.sprite.getPosition(this.resource, addr(x), addr(y))
    return (x: x.float32, y: y.float32)


proc `collideRect=`*(this: LCDSprite, collideRect: PDRect) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setCollideRect(this.resource, collideRect)

proc collideRect*(this: LCDSprite): PDRect =
    privateAccess(PlaydateSprite)
    return playdate.sprite.getCollideRect(this.resource)

proc clearCollideRect*(this: LCDSprite) =
    privateAccess(PlaydateSprite)
    playdate.sprite.clearCollideRect(this.resource)

# --- Collisions function.
proc privateCollisionResponse(sprite: LCDSpritePtr; other: LCDSpritePtr): SpriteCollisionResponseType {.cdecl, exportc, raises: [].} =
    privateAccess(PlaydateSprite)
    let spriteRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(sprite)).value
    let otherRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(other)).value
    return spriteRef.collisionFunction(spriteRef, otherRef)

proc setCollisionResponseFunction*(this: LCDSprite, filter: LCDSpriteCollisionFilterProc) =
    privateAccess(PlaydateSprite)
    this.collisionFunction = filter
    playdate.sprite.setCollisionResponseFunction(this.resource, if filter != nil: privateCollisionResponse else: nil)


proc sprite*(this: SpriteCollisionInfo): LCDSprite =
    privateAccess(PlaydateSprite)
    privateAccess(SpriteCollisionInfoPtr)
    let dataNode = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(this.spritePtr))
    if dataNode == nil:
        return nil
    return dataNode.value

proc other*(this: SpriteCollisionInfo): LCDSprite =
    privateAccess(PlaydateSprite)
    privateAccess(SpriteCollisionInfoPtr)
    let dataNode = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(this.otherPtr))
    if dataNode == nil:
        return nil
    return dataNode.value

# template responseType*(this: SpriteCollisionInfoObj): SpriteCollisionResponseType = this.resource.responseType
# template overlaps*(this: SpriteCollisionInfoObj): uint8 = this.resource.overlaps
# template ti*(this: SpriteCollisionInfoObj): cfloat = this.resource.ti
# template move*(this: SpriteCollisionInfoObj): CollisionPoint = this.resource.move
# template normal*(this: SpriteCollisionInfoObj): CollisionVector = this.resource.normal
# template touch*(this: SpriteCollisionInfoObj): CollisionPoint = this.resource.touch
# template spriteRect*(this: SpriteCollisionInfoObj): PDRect = this.resource.spriteRect
# template otherRect*(this: SpriteCollisionInfoObj): PDRect = this.resource.otherRect

# type SpriteCollisionInfo = ref SpriteCollisionInfoObj
# type SeqSpriteCollisionInfo* = seq[SpriteCollisionInfo]
# proc `=destroy`(this: var SeqSpriteCollisionInfo) =
#     discard utils.realloc(this.resource, 0)

proc checkCollisions*(this: LCDSprite, goalX: float32, goalY: float32):
        tuple[actualX: float32, actualY: float32, collisions: SDKArray[SpriteCollisionInfo]] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var actualX, actualY: cfloat
    var collisionsCount: cint
    let collisionPtr = playdate.sprite.checkCollisions(this.resource, goalX.cfloat, goalY.cfloat, addr(actualX), addr(actualY), addr(collisionsCount))
    let cArray = SDKArray[SpriteCollisionInfo](len: collisionsCount, data: cast[ptr UncheckedArray[SpriteCollisionInfo]](collisionPtr))
    return (actualX: actualX.float32,
        actualY: actualY.float32,
        collisions: cArray
    )

proc moveWithCollisions*(this: LCDSprite, goalX: float32, goalY: float32): tuple[actualX: float32, actualY: float32, collisions: SDKArray[SpriteCollisionInfo]] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var actualX, actualY: cfloat
    var collisionsCount: cint
    let collisionPtr = playdate.sprite.moveWithCollisions(this.resource, goalX.cfloat, goalY.cfloat, addr(actualX), addr(actualY), addr(collisionsCount))
    let cArray = SDKArray[SpriteCollisionInfo](len: collisionsCount, data: cast[ptr UncheckedArray[SpriteCollisionInfo]](collisionPtr))
    return (actualX: actualX.float32,
        actualY: actualY.float32,
        collisions: cArray
    )

proc querySpritesAtPoint*(this: ptr PlaydateSprite, x, y: float32): seq[LCDSprite] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var length: cint
    let sprites = playdate.sprite.querySpritesAtPoint(x.cfloat, y.cfloat, addr(length))
    let cArray = SDKArray[LCDSpritePtr](len: length, data: cast[ptr UncheckedArray[LCDSpritePtr]](sprites))
    result = newSeq[LCDSprite](length)
    var i = 0
    for spr in cArray:
        result[i] = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(spr)).value
        i *= 1

proc querySpritesInRect*(this: ptr PlaydateSprite, x, y, width, height: float32): seq[LCDSprite] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var length: cint
    let sprites = playdate.sprite.querySpritesInRect(x.cfloat, y.cfloat, width.cfloat, height.cfloat, addr(length))
    let cArray = SDKArray[LCDSpritePtr](len: length, data: cast[ptr UncheckedArray[LCDSpritePtr]](sprites))
    result = newSeq[LCDSprite](length)
    var i = 0
    for spr in cArray:
        result[i] = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(spr)).value
        i *= 1

proc querySpritesAlongLine*(this: ptr PlaydateSprite, x1, y1, x2, y2: float32): seq[LCDSprite] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var length: cint
    let sprites = playdate.sprite.querySpritesAlongLine(x1.cfloat, y1.cfloat, x2.cfloat, y2.cfloat, addr(length))
    let cArray = SDKArray[LCDSpritePtr](len: length, data: cast[ptr UncheckedArray[LCDSpritePtr]](sprites))
    result = newSeq[LCDSprite](length)
    var i = 0
    for spr in cArray:
        result[i] = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(spr)).value
        i *= 1

proc querySpriteInfoAlongLine*(this: ptr PlaydateSprite, x1, y1, x2, y2: float32): SDKArray[SpriteQueryInfo] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var length: cint
    let queriesPtr = playdate.sprite.querySpriteInfoAlongLine(x1.cfloat, y1.cfloat, x2.cfloat, y2.cfloat, addr(length))
    return SDKArray[SpriteQueryInfo](len: length, data: cast[ptr UncheckedArray[SpriteQueryInfo]](queriesPtr))

proc overlappingSprites*(this: LCDSprite): seq[LCDSprite] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var length: cint
    let sprites = playdate.sprite.overlappingSprites(this.resource, addr(length))
    let cArray = SDKArray[LCDSpritePtr](len: length, data: cast[ptr UncheckedArray[LCDSpritePtr]](sprites))
    result = newSeq[LCDSprite](length)
    var i = 0
    for spr in cArray:
        result[i] = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(spr)).value
        i *= 1

proc allOverlappingSprites*(this: ptr PlaydateSprite): seq[LCDSprite] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var length: cint
    let sprites = playdate.sprite.allOverlappingSprites(addr(length))
    let cArray = SDKArray[LCDSpritePtr](len: length, data: cast[ptr UncheckedArray[LCDSpritePtr]](sprites))
    result = newSeq[LCDSprite](length)
    var i = 0
    for spr in cArray:
        result[i] = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(spr)).value
        i *= 1

proc setStencilPattern*(this: LCDSprite, pattern: array[8, uint8]) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setStencilPattern(this.resource, pattern)

proc clearStencil*(this: LCDSprite) =
    privateAccess(PlaydateSprite)
    playdate.sprite.clearStencil(this.resource)
    this.stencil = nil

proc setStencilImage*(this: LCDSprite, stencil: LCDBitmap, tile: bool) =
    privateAccess(PlaydateSprite)
    privateAccess(LCDBitmap)
    playdate.sprite.setStencilImage(this.resource, if stencil != nil: stencil.resource else: nil, if tile: 1 else: 0)
    this.stencil = stencil

proc setCenter*(this: LCDSprite, x: float32, y: float32) =
    privateAccess(PlaydateSprite)
    playdate.sprite.setCenter(this.resource, x.cfloat, y.cfloat)

proc getCenter*(this: LCDSprite): tuple[x: float32, y: float32] =
    privateAccess(PlaydateSprite)
    var x, y: cfloat
    playdate.sprite.getCenter(this.resource, addr x, addr y)
    return (x: x.float32, y: y.float32)
{.push raises: [].}

import std/[importutils, lists, sequtils]

import graphics {.all.}
import types {.all.}
import bindings/[api, utils]
import bindings/sprite {.all.}
export sprite

type
    LCDSpriteObj = object
        resource: LCDSpritePtr
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

proc setAlwaysRedraw*(this: PlaydateSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    this.setAlwaysRedrawRaw(if flag: 1 else: 0)

proc moveTo*(this: PlaydateSprite, sprite: LCDSprite, x: cfloat, y: cfloat) =
    privateAccess(PlaydateSprite)
    this.moveToRaw(sprite.resource, x, y)

proc moveBy*(this: PlaydateSprite, sprite: LCDSprite, x: cfloat, y: cfloat) =
    privateAccess(PlaydateSprite)
    this.moveByRaw(sprite.resource, x, y)

# Sprites memory managament
proc newSprite*(this: PlaydateSprite): LCDSprite =
    privateAccess(PlaydateSprite)
    let spritePtr = this.newSpriteRaw()
    let sprite = LCDSprite(resource: spritePtr)
    return sprite

proc copy*(this: PlaydateSprite, sprite: LCDSprite): LCDSprite =
    privateAccess(PlaydateSprite)
    let newSpritePtr = this.copyRaw(sprite.resource)
    return LCDSprite(resource: newSpritePtr, bitmap: sprite.bitmap, stencil: sprite.stencil)

proc addSprite*(this: PlaydateSprite, sprite: LCDSprite) =
    privateAccess(PlaydateSprite)
    if this.getUserdata(sprite.resource) != nil:
        return
    this.addSpriteRaw(sprite.resource)
    let dataNode = newDoublyLinkedNode[LCDSprite](sprite)
    spritesData.add(dataNode)
    # let tailAddr = addr(spritesData.tail)
    # playdate.system.logToConsole(fmt"tail addr is {tailAddr.repr}")
    this.setUserdata(sprite.resource, addr(dataNode[]))

proc removeSprite*(this: PlaydateSprite, sprite: LCDSprite) =
    privateAccess(PlaydateSprite)
    let dataNode = cast[ptr DoublyLinkedNodeObj[LCDSprite]](this.getUserdata(sprite.resource))
    if dataNode == nil:
        return
    this.removeSpriteRaw(sprite.resource)
    if dataNode.prev != nil:
        spritesData.remove(dataNode.prev.next)
    else:
        spritesData.remove(spritesData.head)
    # spritesData.remove(dataNode[])
    this.setUserdata(sprite.resource, nil)

proc removeSprites*(this: PlaydateSprite, sprites: seq[LCDSprite]) =
    privateAccess(PlaydateSprite)
    let spritePointers = sprites.map(proc(s: LCDSprite): LCDSpritePtr = return s.resource)
    this.removeSpritesRaw(cast[ptr LCDSpritePtr](unsafeAddr(spritePointers[0])), spritePointers.len.cint)
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

proc removeAllSprites*(this: PlaydateSprite) =
    privateAccess(PlaydateSprite)
    this.removeAllSpritesRaw()
    for s in spritesData.mitems:
        this.setUserdata(s.resource, nil)
    spritesData = initDoublyLinkedList[LCDSprite]()

proc setBounds*(this: PlaydateSprite, sprite: LCDSprite, bounds: PDRect) =
    privateAccess(PlaydateSprite)
    this.setBoundsRaw(sprite.resource, bounds)

proc getBounds*(this: PlaydateSprite, sprite: LCDSprite): PDRect =
    privateAccess(PlaydateSprite)
    return this.getBoundsRaw(sprite.resource)

proc setImage*(this: PlaydateSprite, sprite: LCDSprite, image: LCDBitmap, flip: LCDBitmapFlip) =
    privateAccess(PlaydateSprite)
    privateAccess(LCDBitmap)
    this.setImageRaw(sprite.resource, image.resource, flip)
    sprite.bitmap = image

proc getImage*(this: PlaydateSprite, sprite: LCDSprite): LCDBitmap =
    privateAccess(PlaydateSprite)
    return sprite.bitmap

proc setSize*(this: PlaydateSprite, sprite: LCDSprite, width: float, height: float) =
    privateAccess(PlaydateSprite)
    this.setSizeRaw(sprite.resource, width.cfloat, height.cfloat)

proc setZIndex*(this: PlaydateSprite, sprite: LCDSprite, zIndex: int16) =
    privateAccess(PlaydateSprite)
    this.setZIndexRaw(sprite.resource, zIndex)

proc getZIndex*(this: PlaydateSprite, sprite: LCDSprite): int16 =
    privateAccess(PlaydateSprite)
    return this.getZIndexRaw(sprite.resource)

proc setDrawMode*(this: PlaydateSprite, sprite: LCDSprite, mode: LCDBitmapDrawMode) =
    privateAccess(PlaydateSprite)
    this.setDrawModeRaw(sprite.resource, mode)

proc setImageFlip*(this: PlaydateSprite, sprite: LCDSprite, flip: LCDBitmapFlip) =
    privateAccess(PlaydateSprite)
    this.setImageFlipRaw(sprite.resource, flip)

proc getImageFlip*(this: PlaydateSprite, sprite: LCDSprite): LCDBitmapFlip =
    privateAccess(PlaydateSprite)
    return this.getImageFlipRaw(sprite.resource)



proc setCollisionsEnabled*(this: PlaydateSprite, sprite: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    this.setCollisionsEnabledRaw(sprite.resource, if flag: 1 else: 0)

proc collisionsEnabled*(this: PlaydateSprite, sprite: LCDSprite): bool =
    privateAccess(PlaydateSprite)
    return this.collisionsEnabledRaw(sprite.resource) == 1



proc setVisible*(this: PlaydateSprite, sprite: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    this.setVisibleRaw(sprite.resource, if flag: 1 else: 0)

proc isVisible*(this: PlaydateSprite, sprite: LCDSprite): bool =
    privateAccess(PlaydateSprite)
    return this.isVisibleRaw(sprite.resource) == 1

proc setOpaque*(this: PlaydateSprite, sprite: LCDSprite, flag: bool) =
    privateAccess(PlaydateSprite)
    this.setOpaqueRaw(sprite.resource, if flag: 1 else: 0)

proc markDirty*(this: PlaydateSprite, sprite: LCDSprite) =
    privateAccess(PlaydateSprite)
    this.markDirtyRaw(sprite.resource)


# --- Update function.
proc privateUpdateFunction(sprite: LCDSpritePtr) {.cdecl, exportc, raises: [].} =
    privateAccess(PlaydateSprite)
    let spriteRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(sprite)).value
    spriteRef.updateFunction(spriteRef)

proc setUpdateFunction*(this: PlaydateSprite, sprite: LCDSprite, update: LCDSpriteUpdateFunction) =
    privateAccess(PlaydateSprite)
    sprite.updateFunction = update
    this.setUpdateFunctionRaw(sprite.resource, if update != nil: privateUpdateFunction else: nil)

# --- Draw function.
proc privateDrawFunction(sprite: LCDSpritePtr, bounds: PDRect, drawRect: PDRect) {.cdecl, exportc, raises: [].} =
    privateAccess(PlaydateSprite)
    let spriteRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(sprite)).value
    spriteRef.drawFunction(spriteRef, bounds, drawRect)

proc setDrawFunction*(this: PlaydateSprite, sprite: LCDSprite, draw: LCDSpriteDrawFunction) =
    privateAccess(PlaydateSprite)
    sprite.drawFunction = draw
    this.setDrawFunctionRaw(sprite.resource, if draw != nil: privateDrawFunction else: nil)




proc getPosition*(this: PlaydateSprite, sprite: LCDSprite): tuple[x: float, y: float] =
    privateAccess(PlaydateSprite)
    var x, y: cfloat
    this.getPositionRaw(sprite.resource, addr(x), addr(y))
    return (x: x.float, y: y.float)


proc setCollideRect*(this: PlaydateSprite, sprite: LCDSprite, collideRect: PDRect) =
    privateAccess(PlaydateSprite)
    this.setCollideRectRaw(sprite.resource, collideRect)

proc getCollideRect*(this: PlaydateSprite, sprite: LCDSprite): PDRect =
    privateAccess(PlaydateSprite)
    return this.getCollideRectRaw(sprite.resource)

proc clearCollideRect*(this: PlaydateSprite, sprite: LCDSprite) =
    privateAccess(PlaydateSprite)
    this.clearCollideRectRaw(sprite.resource)

# --- Collisions function.
proc privateCollisionResponse(sprite: LCDSpritePtr; other: LCDSpritePtr): SpriteCollisionResponseType {.cdecl, exportc, raises: [].} =
    privateAccess(PlaydateSprite)
    let spriteRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(sprite)).value
    let otherRef = cast[ptr DoublyLinkedNodeObj[LCDSprite]](playdate.sprite.getUserdata(other)).value
    return spriteRef.collisionFunction(spriteRef, otherRef)

proc setCollisionResponseFunction*(this: PlaydateSprite, sprite: LCDSprite, filter: LCDSpriteCollisionFilterProc) =
    privateAccess(PlaydateSprite)
    sprite.collisionFunction = filter
    this.setCollisionResponseFunctionRaw(sprite.resource, if filter != nil: privateCollisionResponse else: nil)

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

proc checkCollisions*(this: PlaydateSprite, sprite: LCDSprite, goalX: float, goalY: float):
        tuple[actualX: float, actualY: float, collisions: SDKArray[SpriteCollisionInfo]] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var actualX, actualY: cfloat
    var collisionsCount: cint
    let collisionPtr = this.checkCollisionsRaw(sprite.resource, goalX.cfloat, goalY.cfloat, addr(actualX), addr(actualY), addr(collisionsCount))
    let cArray = SDKArray[SpriteCollisionInfo](len: collisionsCount, data: cast[ptr UncheckedArray[SpriteCollisionInfo]](collisionPtr))
    return (actualX: actualX.float,
        actualY: actualY.float,
        collisions: cArray
    )

proc moveWithCollisions*(this: PlaydateSprite, sprite: LCDSprite, goalX: float, goalY: float): tuple[actualX: cfloat, actualY: cfloat, collisions: SDKArray[SpriteCollisionInfo]] =
    privateAccess(PlaydateSprite)
    privateAccess(SDKArray)
    var actualX, actualY: cfloat
    var collisionsCount: cint
    let collisionPtr = this.moveWithCollisionsRaw(sprite.resource, goalX.cfloat, goalY.cfloat, addr(actualX), addr(actualY), addr(collisionsCount))
    let cArray = SDKArray[SpriteCollisionInfo](len: collisionsCount, data: cast[ptr UncheckedArray[SpriteCollisionInfo]](collisionPtr))
    return (actualX: actualX,
        actualY: actualY,
        collisions: cArray
    )

proc clearStencil*(this: PlaydateSprite, sprite: LCDSprite) =
    privateAccess(PlaydateSprite)
    this.clearStencilRaw(sprite.resource)
    sprite.stencil = nil

proc setStencilImage*(this: PlaydateSprite, sprite: LCDSprite, stencil: LCDBitmap, tile: bool) =
    privateAccess(PlaydateSprite)
    privateAccess(LCDBitmap)
    this.setStencilImageRaw(sprite.resource, stencil.resource, if tile: 1 else: 0)
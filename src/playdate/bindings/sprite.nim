import graphics, utils, types

type SpriteCollisionResponseType* {.size: sizeof(cint), importc: "SpriteCollisionResponseType".} = enum
    kCollisionTypeSlide, kCollisionTypeFreeze, kCollisionTypeOverlap,
    kCollisionTypeBounce

type PDRect* {.importc: "PDRect", header: "pd_api.h", bycopy.} = object
    x* {.importc: "x".}: cfloat
    y* {.importc: "y".}: cfloat
    width* {.importc: "width".}: cfloat
    height* {.importc: "height".}: cfloat

proc PDRectMake*(x: cfloat; y: cfloat; width: cfloat; height: cfloat): PDRect {.inline,
    cdecl, importc: "PDRectMake".} =
    return PDRect(x: x, y: y, width: width, height: height)

type CollisionPoint* {.importc: "CollisionPoint", header: "pd_api.h", bycopy.} = object
    x* {.importc: "x".}: cfloat
    y* {.importc: "y".}: cfloat

type CollisionVector* {.importc: "CollisionVector", header: "pd_api.h", bycopy.} = object
    x* {.importc: "x".}: cint
    y* {.importc: "y".}: cint

type LCDSpritePtr {.importc: "LCDSprite*", header: "pd_api.h".} = pointer

type SpriteCollisionInfo* {.importc: "SpriteCollisionInfo", header: "pd_api.h", bycopy.} = object
    spritePtr {.importc: "sprite".}: LCDSpritePtr ##  The sprite being moved
    otherPtr {.importc: "other".}: LCDSpritePtr ##  The sprite colliding with the sprite being moved
    responseType* {.importc: "responseType".}: SpriteCollisionResponseType ##  The result of collisionResponse
    overlaps* {.importc: "overlaps".}: uint8 ##  True if the sprite was overlapping other when the collision started. False if it didn’t overlap but tunneled through other.
    ti* {.importc: "ti".}: cfloat ##  A number between 0 and 1 indicating how far along the movement to the goal the collision occurred
    move* {.importc: "move".}: CollisionPoint ##  The difference between the original coordinates and the actual ones when the collision happened
    normal* {.importc: "normal".}: CollisionVector ##  The collision normal; usually -1, 0, or 1 in x and y. Use this value to determine things like if your character is touching the ground.
    touch* {.importc: "touch".}: CollisionPoint ##  The coordinates where the sprite started touching other
    spriteRect* {.importc: "spriteRect".}: PDRect ##  The rectangle the sprite occupied when the touch happened
    otherRect* {.importc: "otherRect".}: PDRect ##  The rectangle the sprite being collided with occupied when the touch happened
type SpriteCollisionInfoPtr = ptr SpriteCollisionInfo

type SpriteQueryInfo* {.importc: "SpriteQueryInfo", header: "pd_api.h", bycopy.} = object
    sprite* {.importc: "sprite".}: LCDSpritePtr ##  The sprite being intersected by the segment
                                            ##  ti1 and ti2 are numbers between 0 and 1 which indicate how far from the starting point of the line segment the collision happened
    ti1* {.importc: "ti1".}: cfloat ##  entry point
    ti2* {.importc: "ti2".}: cfloat ##  exit point
    entryPoint* {.importc: "entryPoint".}: CollisionPoint ##  The coordinates of the first intersection between sprite and the line segment
    exitPoint* {.importc: "exitPoint".}: CollisionPoint ##  The coordinates of the second intersection between sprite and the line segment

# type CWCollisionInfo*
# type CWItemInfo*
type LCDSpriteDrawFunctionRaw = proc (sprite: LCDSpritePtr; bounds: PDRect; drawrect: PDRect): void {.cdecl.}
type LCDSpriteUpdateFunctionRaw = proc (sprite: LCDSpritePtr): void {.cdecl.}
type LCDSpriteCollisionFilterProcRaw = proc (sprite: LCDSpritePtr; other: LCDSpritePtr): SpriteCollisionResponseType {.cdecl, raises: [].}

sdktype:
    type PlaydateSprite* {.importc: "const struct playdate_sprite", header: "pd_api.h", bycopy.} = object
        setAlwaysRedraw {.importc: "setAlwaysRedraw".}: proc (flag: cint) {.cdecl, raises: [].}
        addDirtyRect* {.importc: "addDirtyRect".}: proc (dirtyRect: LCDRect) {.cdecl, raises: [].}
        drawSprites* {.importc: "drawSprites".}: proc () {.cdecl, raises: [].}
        updateAndDrawSprites* {.importc: "updateAndDrawSprites".}: proc () {.cdecl, raises: [].}

        newSprite {.importc: "newSprite".}: proc (): LCDSpritePtr {.cdecl, raises: [].}
        freeSprite {.importc: "freeSprite".}: proc (sprite: LCDSpritePtr) {.cdecl, raises: [].}
        copy {.importc: "copy".}: proc (sprite: LCDSpritePtr): LCDSpritePtr {.cdecl, raises: [].}

        addSprite {.importc: "addSprite".}: proc (sprite: LCDSpritePtr) {.cdecl, raises: [].}
        removeSprite {.importc: "removeSprite".}: proc (sprite: LCDSpritePtr) {.cdecl, raises: [].}
        removeSprites {.importc: "removeSprites".}: proc (sprites: ptr LCDSpritePtr;
            count: cint) {.cdecl, raises: [].}
        removeAllSprites {.importc: "removeAllSprites".}: proc () {.cdecl, raises: [].}
        getSpriteCount {.importsdk.}: proc (): cint

        setBounds {.importc: "setBounds".}: proc (sprite: LCDSpritePtr; bounds: PDRect) {.
            cdecl, raises: [].}
        getBounds {.importc: "getBounds".}: proc (sprite: LCDSpritePtr): PDRect {.cdecl, raises: [].}
        moveTo {.importc: "moveTo".}: proc (sprite: LCDSpritePtr; x: cfloat; y: cfloat) {.
            cdecl, raises: [].}
        moveBy {.importc: "moveBy".}: proc (sprite: LCDSpritePtr; dx: cfloat; dy: cfloat) {.
            cdecl, raises: [].}
        
        setImage {.importc: "setImage".}: proc (sprite: LCDSpritePtr;
            image: LCDBitmapPtr; flip: LCDBitmapFlip) {.cdecl, raises: [].}
        getImage {.importc: "getImage".}: proc (sprite: LCDSpritePtr): LCDBitmapPtr {.
            cdecl, raises: [].}
        setSize {.importc: "setSize".}: proc (s: LCDSpritePtr; width: cfloat;
            height: cfloat) {.cdecl, raises: [].}
        setZIndex {.importc: "setZIndex".}: proc (sprite: LCDSpritePtr; zIndex: int16) {.
            cdecl, raises: [].}
        getZIndex {.importc: "getZIndex".}: proc (sprite: LCDSpritePtr): int16 {.cdecl, raises: [].}

        setDrawMode {.importc: "setDrawMode".}: proc (sprite: LCDSpritePtr;
            mode: LCDBitmapDrawMode) {.cdecl, raises: [].}
        setImageFlip {.importc: "setImageFlip".}: proc (sprite: LCDSpritePtr;
            flip: LCDBitmapFlip) {.cdecl, raises: [].}
        getImageFlip {.importc: "getImageFlip".}: proc (sprite: LCDSpritePtr): LCDBitmapFlip {.
            cdecl, raises: [].}
        # setStencil* {.importc: "setStencil".}: proc (sprite: ptr LCDSprite; stencil: ptr LCDBitmap) {.cdecl.} ##  deprecated in favor of setStencilImage()

        setClipRect {.importc: "setClipRect".}: proc (sprite: LCDSpritePtr;
            clipRect: LCDRect) {.cdecl, raises: [].}
        clearClipRect {.importc: "clearClipRect".}: proc (sprite: LCDSpritePtr) {.cdecl, raises: [].}
        setClipRectsInRange {.importc: "setClipRectsInRange".}: proc (
            clipRect: LCDRect; startZ: cint; endZ: cint) {.cdecl, raises: [].}
        clearClipRectsInRange {.importc: "clearClipRectsInRange".}: proc (startZ: cint;
            endZ: cint) {.cdecl, raises: [].}
        
        setUpdatesEnabled {.importc: "setUpdatesEnabled".}: proc (
            sprite: LCDSpritePtr; flag: cint) {.cdecl, raises: [].}
        updatesEnabled {.importc: "updatesEnabled".}: proc (sprite: LCDSpritePtr): cint {.
            cdecl, raises: [].}
        setCollisionsEnabled {.importc: "setCollisionsEnabled".}: proc (
            sprite: LCDSpritePtr; flag: cint) {.cdecl, raises: [].}
        collisionsEnabled {.importc: "collisionsEnabled".}: proc (sprite: LCDSpritePtr): cint {.
            cdecl, raises: [].}
        setVisible {.importc: "setVisible".}: proc (sprite: LCDSpritePtr; flag: cint) {.
            cdecl, raises: [].}
        isVisible {.importc: "isVisible".}: proc (sprite: LCDSpritePtr): cint {.cdecl, raises: [].}
        setOpaque {.importc: "setOpaque".}: proc (sprite: LCDSpritePtr; flag: cint) {.cdecl, raises: [].}
        markDirty {.importc: "markDirty".}: proc (sprite: LCDSpritePtr) {.cdecl, raises: [].}

        setTag {.importc: "setTag".}: proc (sprite: LCDSpritePtr; tag: uint8) {.cdecl, raises: [].}
        getTag {.importc: "getTag".}: proc (sprite: LCDSpritePtr): uint8 {.cdecl, raises: [].}

        setIgnoresDrawOffset {.importc: "setIgnoresDrawOffset".}: proc (
            sprite: LCDSpritePtr; flag: cint) {.cdecl, raises: [].}
        
        setUpdateFunction {.importc: "setUpdateFunction".}: proc (
            sprite: LCDSpritePtr; `func`: LCDSpriteUpdateFunctionRaw) {.cdecl, raises: [].}
        setDrawFunction {.importc: "setDrawFunction".}: proc (sprite: LCDSpritePtr;
            `func`: LCDSpriteDrawFunctionRaw) {.cdecl, raises: [].}
        
        getPosition {.importc: "getPosition".}: proc (sprite: LCDSpritePtr;
            x: ptr cfloat; y: ptr cfloat) {.cdecl, raises: [].}
        
        ##  Collisions
        resetCollisionWorld* {.importc: "resetCollisionWorld".}: proc () {.cdecl, raises: [].}

        setCollideRect {.importc: "setCollideRect".}: proc (sprite: LCDSpritePtr;
            collideRect: PDRect) {.cdecl, raises: [].}
        getCollideRect {.importc: "getCollideRect".}: proc (sprite: LCDSpritePtr): PDRect {.
            cdecl, raises: [].}
        clearCollideRect {.importc: "clearCollideRect".}: proc (sprite: LCDSpritePtr) {.
            cdecl, raises: [].}
        
        ##  Caller is responsible for freeing the returned array for all collision methods
        setCollisionResponseFunction {.importc: "setCollisionResponseFunction".}: proc (
            sprite: LCDSpritePtr; `func`: LCDSpriteCollisionFilterProcRaw) {.cdecl, raises: [].}
        checkCollisions {.importc: "checkCollisions".}: proc (sprite: LCDSpritePtr;
            goalX: cfloat; goalY: cfloat; actualX: ptr cfloat; actualY: ptr cfloat;
            len: ptr cint): SpriteCollisionInfoPtr {.cdecl, raises: [].}
        moveWithCollisions {.importc: "moveWithCollisions".}: proc (
            sprite: LCDSpritePtr; goalX: cfloat; goalY: cfloat; actualX: ptr cfloat;
            actualY: ptr cfloat; len: ptr cint): SpriteCollisionInfoPtr {.cdecl, raises: [].}
        querySpritesAtPoint {.importc: "querySpritesAtPoint".}: proc (x: cfloat;
            y: cfloat; len: ptr cint): ptr LCDSpritePtr {.cdecl, raises: [].}
        querySpritesInRect {.importc: "querySpritesInRect".}: proc (x: cfloat; y: cfloat;
            width: cfloat; height: cfloat; len: ptr cint): ptr LCDSpritePtr {.cdecl, raises: [].}
        querySpritesAlongLine {.importc: "querySpritesAlongLine".}: proc (x1: cfloat;
            y1: cfloat; x2: cfloat; y2: cfloat; len: ptr cint): ptr LCDSpritePtr {.cdecl, raises: [].}
        querySpriteInfoAlongLine {.importc: "querySpriteInfoAlongLine".}: proc (
            x1: cfloat; y1: cfloat; x2: cfloat; y2: cfloat; len: ptr cint): ptr SpriteQueryInfo {.cdecl, raises: [].}
        overlappingSprites {.importc: "overlappingSprites".}: proc (
            sprite: LCDSpritePtr; len: ptr cint): ptr LCDSpritePtr {.cdecl, raises: [].}
        allOverlappingSprites {.importc: "allOverlappingSprites".}: proc (len: ptr cint): ptr LCDSpritePtr {.
            cdecl, raises: [].}
        
        ##  Added in 1.7
        setStencilPattern {.importc: "setStencilPattern".}: proc (
            sprite: LCDSpritePtr; pattern: array[8, uint8]) {.cdecl, raises: [].}
        clearStencil {.importc: "clearStencil".}: proc (sprite: LCDSpritePtr) {.cdecl, raises: [].}

        setUserdata {.importc: "setUserdata".}: proc (sprite: LCDSpritePtr;
            userdata: pointer) {.cdecl, raises: [].}
        getUserdata {.importc: "getUserdata".}: proc (sprite: LCDSpritePtr): pointer {.
            cdecl, raises: [].}
        
        ##  Added in 1.10
        setStencilImage {.importc: "setStencilImage".}: proc (sprite: LCDSpritePtr;
            stencil: LCDBitmapPtr; tile: cint) {.cdecl, raises: [].}
        setCenter {.importc: "setCenter".}: proc (sprite: LCDSpritePtr;
            x: cfloat; y: cfloat) {.cdecl, raises: [].} ## added in 2.1
        getCenter {.importc: "getCenter".}: proc (sprite: LCDSpritePtr;
            x: ptr cfloat; y: ptr cfloat) {.cdecl, raises: [].}


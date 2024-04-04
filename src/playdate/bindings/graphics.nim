{.push raises: [].}

import utils, types

type LCDRect* {.importc: "LCDRect", header: "pd_api.h".} = object
    left* {.importc.}: int # int32?
    right* {.importc.}: int
    top* {.importc.}: int
    bottom* {.importc.}: int

proc makeLCDRect*(x: int, y: int, width: int, height: int): LCDRect =
    return LCDRect(left: x, right: x + width, top: y, bottom: y + height)

proc translateLCDRect*(rect: LCDRect, dx: int, dy: int): LCDRect {.importc: "PDStringEncoding", header: "pd_api.h".}

const LCD_COLUMNS*: int = 400
const LCD_ROWS*: int = 240
const LCD_ROWSIZE*: int = 52
const LCD_SCREEN_RECT* = makeLCDRect(0, 0, LCD_COLUMNS, LCD_ROWS)

# Enums
type LCDBitmapDrawMode* {.importc: "LCDBitmapDrawMode", header: "pd_api.h".} = enum
    kDrawModeCopy, kDrawModeWhiteTransparent, kDrawModeBlackTransparent,
    kDrawModeFillWhite, kDrawModeFillBlack, kDrawModeXOR, kDrawModeNXOR,
    kDrawModeInverted

type LCDBitmapFlip* {.importc: "LCDBitmapFlip", header: "pd_api.h".} = enum
    kBitmapUnflipped, kBitmapFlippedX, kBitmapFlippedY, kBitmapFlippedXY

type LCDSolidColor* {.importc: "LCDSolidColor", header: "pd_api.h".} = enum
    kColorBlack, kColorWhite, kColorClear, kColorXOR

type LCDLineCapStyle* {.importc: "LCDLineCapStyle", header: "pd_api.h".} = enum
    kLineCapStyleButt, kLineCapStyleSquare, kLineCapStyleRound

type LCDFontLanguage* {.importc: "LCDFontLanguage", header: "pd_api.h".} = enum
    kLCDFontLanguageEnglish, kLCDFontLanguageJapanese, kLCDFontLanguageUnknown

type PDStringEncoding* {.importc: "PDStringEncoding", header: "pd_api.h".} = enum
    kASCIIEncoding, kUTF8Encoding, k16BitLEEncoding


type
    LCDPattern* = ref object
        ## An 8x8 pattern used for drawing. A pattern is an array of 8 numbers describing the
        ## bitmap for each row; for example, { 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 } specifies a
        ## checkerboard pattern. An additional 8 numbers can be specified for an alpha mask bitmap.
        pattern: array[16, uint8]

    LCDPatternPtr = ptr array[16, uint8]

    RawLCDColor {.importc: "LCDColor", header: "pd_api.h".} = cuint # LCDSolidColor or pointer to a LCDPattern

    LCDColor* = LCDSolidColor | LCDPattern
        ## Either a solid color or a pattern.

proc convert(color: LCDColor): RawLCDColor =
    when color is LCDSolidColor: return cast[RawLCDColor](color)
    elif color is LCDPattern: return cast[RawLCDColor](addr color.pattern)

proc makeLCDPattern*(r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, ra, rb, rc, rd, re, rf: uint8): LCDPattern =
    return LCDPattern(pattern: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, ra, rb, rc, rd, re, rf])

proc makeLCDOpaquePattern*(r0, r1, r2, r3, r4, r5, r6, r7: uint8): LCDPattern =
    return makeLCDPattern(r0, r1, r2, r3, r4, r5, r6, r7, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff)

type LCDPolygonFillRule* {.importc: "LCDPolygonFillRule", header: "pd_api.h".} = enum
    kPolygonFillNonZero, kPolygonFillEvenOdd

# Types
type LCDBitmapTablePtr {.importc: "LCDBitmapTable*", header: "pd_api.h".} = pointer

type LCDFontPtr {.importc: "LCDFont*", header: "pd_api.h".} = pointer
type LCDFontObj = object
    resource: LCDFontPtr

proc `=destroy`(this: var LCDFontObj) = deallocImpl(this.resource)

type LCDFont* = ref LCDFontObj

type LCDFontDataPtr {.importc: "LCDFontData*", header: "pd_api.h".} = object
type LCDFontData* = LCDFontDataPtr

type LCDFontPagePtr {.importc: "LCDFontPage*", header: "pd_api.h".} = pointer
type LCDFontPageObj = object
    resource: LCDFontPagePtr

proc `=destroy`(this: var LCDFontPageObj) = deallocImpl(this.resource)

type LCDFontPage* = ref LCDFontPageObj

type LCDFontGlyphPtr {.importc: "LCDFontGlyph*", header: "pd_api.h".} = pointer
type LCDFontGlyphObj = object
    resource: LCDFontGlyphPtr

proc `=destroy`(this: var LCDFontGlyphObj) = deallocImpl(this.resource)

type LCDFontGlyph* = ref LCDFontGlyphObj

type LCDVideoPlayerRaw {.importc: "LCDVideoPlayer", header: "pd_api.h".} = object
type LCDVideoPlayerPtr = ptr LCDVideoPlayerRaw

# Video
type PlaydateVideo* {.importc: "const struct playdate_video", header: "pd_api.h".} = object
    loadVideo {.importc: "loadVideo".}: proc (path: cstring): LCDVideoPlayerPtr {.cdecl, raises: [].}
    freePlayer {.importc: "freePlayer".}: proc (p: LCDVideoPlayerPtr) {.cdecl, raises: [].}
    setContext {.importc: "setContext".}: proc (p: LCDVideoPlayerPtr;
        context: LCDBitmapPtr): cint {.cdecl, raises: [].}
    useScreenContext {.importc: "useScreenContext".}: proc (p: LCDVideoPlayerPtr) {.cdecl, raises: [].}
    renderFrame {.importc: "renderFrame".}: proc (p: LCDVideoPlayerPtr; n: cint): cint {.cdecl, raises: [].}
    getError {.importc: "getError".}: proc (p: LCDVideoPlayerPtr): cstring {.cdecl, raises: [].}
    getInfo {.importc: "getInfo".}: proc (p: LCDVideoPlayerPtr; outWidth: ptr cint;
                                    outHeight: ptr cint;
                                    outFrameRate: ptr cfloat;
                                    outFrameCount: ptr cint;
                                    outCurrentFrame: ptr cint) {.cdecl, raises: [].}
    getContext {.importc: "getContext".}: proc (p: LCDVideoPlayerPtr): LCDBitmapPtr {.cdecl, raises: [].}

# Graphics
sdktype:
    type PlaydateGraphics* {.importc: "const struct playdate_graphics", header: "pd_api.h".} = object
        video* {.importc: "video".}: ptr PlaydateVideo
        clear {.importsdk.}: proc (color: RawLCDColor) {.cdecl, raises: [].}

        setBackgroundColor* {.importc: "setBackgroundColor".}: proc (
            color: LCDSolidColor) {.cdecl, raises: [].}
        # setStencil* {.importc: "setStencil".}: proc (stencil: ptr LCDBitmap) {.cdecl.} ##  deprecated in favor of setStencilImage, which adds a "tile" flag
        setDrawMode* {.importc: "setDrawMode".}: proc (mode: LCDBitmapDrawMode) {.cdecl, raises: [].}
        setDrawOffset {.importsdk.}: proc (dx: cint; dy: cint)
        setClipRect {.importsdk.}: proc (x: cint; y: cint; width: cint; height: cint)
        clearClipRect* {.importc: "clearClipRect".}: proc () {.cdecl, raises: [].}
        setLineCapStyle* {.importc: "setLineCapStyle".}: proc (
            endCapStyle: LCDLineCapStyle) {.cdecl, raises: [].}

        setFont {.importc: "setFont".}: proc (font: LCDFontPtr) {.cdecl, raises: [].}

        setTextTracking* {.importsdk.}: proc (tracking: cint)
        pushContext {.importc: "pushContext".}: proc (target: LCDBitmapPtr) {.cdecl, raises: [].}
        popContext* {.importc: "popContext".}: proc () {.cdecl, raises: [].}
        drawBitmap {.importc: "drawBitmap".}: proc (bitmap: LCDBitmapPtr; x: int; y: int;
            flip: LCDBitmapFlip) {.cdecl, raises: [].}

        tileBitmap {.importc: "tileBitmap".}: proc (bitmap: LCDBitmapPtr; x: cint; y: cint;
            width: cint; height: cint; flip: LCDBitmapFlip) {.cdecl, raises: [].}
        drawLine {.importsdk.}: proc (x1: cint; y1: cint; x2: cint; y2: cint;
            width: cint; color: RawLCDColor)
        fillTriangle {.importsdk.}: proc (x1: cint; y1: cint; x2: cint;
            y2: cint; x3: cint; y3: cint; color: RawLCDColor)
        drawRect {.importsdk.}: proc (x: cint; y: cint; width: cint; height: cint;
            color: RawLCDColor)
        fillRect {.importsdk.}: proc (x: cint; y: cint; width: cint; height: cint;
            color: RawLCDColor)
        drawEllipse {.importsdk.}: proc (x: cint; y: cint; width: cint;
            height: cint; lineWidth: cint; startAngle: cfloat; endAngle: cfloat;
            color: RawLCDColor) ##  stroked inside the rect
        fillEllipse {.importsdk.}: proc (x: cint; y: cint; width: cint;
            height: cint; startAngle: cfloat; endAngle: cfloat; color: RawLCDColor)
        drawScaledBitmap {.importc: "drawScaledBitmap".}: proc (bitmap: LCDBitmapPtr;
            x: cint; y: cint; xscale: cfloat; yscale: cfloat) {.cdecl, raises: [].}

        drawText {.importsdk.}: proc (text: cstring, len: csize_t,
            encoding: PDStringEncoding, x: cint, y: cint): cint {.discardable.}

        newBitmap {.importc: "newBitmap".}: proc (width: cint; height: cint;
            bgcolor: RawLCDColor): LCDBitmapPtr {.cdecl, raises: [].}
        freeBitmap {.importc: "freeBitmap".}: proc (bitmap: LCDBitmapPtr) {.cdecl, raises: [].}
        loadBitmap {.importc: "loadBitmap".}: proc (path: cstring; outerr: ptr cstring): LCDBitmapPtr {.
            cdecl, raises: [].}

        copyBitmap {.importc: "copyBitmap".}: proc (bitmap: LCDBitmapPtr): LCDBitmapPtr {.
            cdecl, raises: [].}
        loadIntoBitmap {.importc: "loadIntoBitmap".}: proc (path: cstring;
            bitmap: LCDBitmapPtr; outerr: ptr cstring) {.cdecl, raises: [].}
        getBitmapData {.importc: "getBitmapData".}: proc (bitmap: LCDBitmapPtr;
            width: ptr cint; height: ptr cint; rowbytes: ptr cint; mask: ptr ptr uint8;
            data: ptr ptr uint8) {.cdecl, raises: [].}
        clearBitmap {.importsdk.}: proc (bitmap: LCDBitmapPtr; bgcolor: RawLCDColor) {.cdecl, raises: [].}
        rotatedBitmap {.importc: "rotatedBitmap".}: proc (bitmap: LCDBitmapPtr;
            rotation: cfloat; xscale: cfloat; yscale: cfloat; allocedSize: ptr cint): LCDBitmapPtr {.
            cdecl, raises: [].}

        newBitmapTable {.importc: "newBitmapTable".}: proc (count: cint; width: cint;
            height: cint): LCDBitmapTablePtr {.cdecl, raises: [].}
        freeBitmapTable {.importc: "freeBitmapTable".}: proc (table: LCDBitmapTablePtr) {.
            cdecl, raises: [].}
        loadBitmapTable {.importc: "loadBitmapTable".}: proc (path: cstring;
            outerr: ptr cstring): LCDBitmapTablePtr {.cdecl, raises: [].}
        loadIntoBitmapTable {.importc: "loadIntoBitmapTable".}: proc (path: cstring;
            table: LCDBitmapTablePtr; outerr: ptr cstring) {.cdecl, raises: [].}
        getTableBitmap {.importc: "getTableBitmap".}: proc (table: LCDBitmapTablePtr;
            idx: cint): LCDBitmapPtr {.cdecl, raises: [].}

        loadFont {.importc: "loadFont".}: proc (path: cstring, outErr: ptr cstring): LCDFontPtr {.cdecl, raises: [].}

        getFontPage {.importc: "getFontPage".}: proc (font: LCDFontPtr; c: uint32): LCDFontPagePtr {.
            cdecl, raises: [].}
        getPageGlyph {.importc: "getPageGlyph".}: proc (page: LCDFontPagePtr; c: uint32;
            bitmap: ptr LCDBitmapPtr; advance: ptr cint): LCDFontGlyphPtr {.cdecl, raises: [].}
        getGlyphKerning {.importc: "getGlyphKerning".}: proc (glyph: LCDFontGlyphPtr;
            glyphcode: uint32; nextcode: uint32): cint {.cdecl, raises: [].}

        getTextWidth {.importc.}: proc (font: LCDFontPtr, text: cstring;
            len: csize_t; encoding: PDStringEncoding; tracking: cint): cint {.cdecl, raises: [].}

        getFrame {.importc: "getFrame".}: proc (): ptr uint8 {.cdecl, raises: [].} ##  row stride = LCD_ROWSIZE
        getDisplayFrame {.importc: "getDisplayFrame".}: proc (): ptr uint8 {.cdecl, raises: [].} ##  row stride = LCD_ROWSIZE
        getDebugBitmap {.importc: "getDebugBitmap".}: proc (): LCDBitmapPtr {.cdecl, raises: [].} ##  valid in simulator only, function is NULL on device
        copyFrameBufferBitmap {.importc: "copyFrameBufferBitmap".}: proc (): LCDBitmapPtr {.
            cdecl, raises: [].}
        markUpdatedRows {.importsdk.}: proc (start: cint; to: cint)
        display* {.importsdk.}: proc () ##  misc util.

        setColorToPattern {.importsdk.}: proc (color: LCDPatternPtr;
            bitmap: LCDBitmapPtr; x: cint; y: cint) {.cdecl, raises: [].}
        checkMaskCollision {.importsdk.}: proc (
            bitmap1: LCDBitmapPtr; x1: cint; y1: cint; flip1: LCDBitmapFlip;
            bitmap2: LCDBitmapPtr; x2: cint; y2: cint; flip2: LCDBitmapFlip; rect: LCDRect): cint ##  1.1
        setScreenClipRect {.importsdk.}: proc (x: cint; y: cint;
            width: cint; height: cint) ##  1.1.1
        fillPolygon {.importc: "fillPolygon".}: proc (nPoints: cint; coords: ptr cint;
            color: RawLCDColor; fillrule: LCDPolygonFillRule) {.cdecl, raises: [].}
        getFontHeight {.importc: "getFontHeight".}: proc (font: LCDFontPtr): uint8 {.
            cdecl, raises: [].}               ##  1.7
        getDisplayBufferBitmap {.importc: "getDisplayBufferBitmap".}: proc (): LCDBitmapPtr {.
            cdecl, raises: [].} # system owned, don't free.
        drawRotatedBitmap {.importc: "drawRotatedBitmap".}: proc (
            bitmap: LCDBitmapPtr; x: cint; y: cint; rotation: cfloat; centerx: cfloat;
            centery: cfloat; xscale: cfloat; yscale: cfloat) {.cdecl, raises: [].}
        setTextLeading {.importsdk.}: proc (lineHeightAdjustment: cint) ##  1.8
        setBitmapMask {.importc: "setBitmapMask".}: proc (bitmap: LCDBitmapPtr;
            mask: LCDBitmapPtr): cint {.cdecl, raises: [].}
        getBitmapMask {.importc: "getBitmapMask".}: proc (bitmap: LCDBitmapPtr): LCDBitmapPtr {.
            cdecl, raises: [].}               ##  1.10
        setStencilImage {.importc: "setStencilImage".}: proc (stencil: LCDBitmapPtr;
            tile: cint) {.cdecl, raises: [].}   ##  1.12
        makeFontFromData {.importc: "makeFontFromData".}: proc (data: LCDFontDataPtr;
            wide: cint): LCDFontPtr {.cdecl, raises: [].}
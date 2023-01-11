{.push raises: [].}

import std/importutils

import bindings/[api, types]
import bindings/graphics

# Only export public symbols, then import all
export graphics
{.hint[DuplicateModuleImport]: off.}
import bindings/graphics {.all.}

type LCDBitmapObj = object of RootObj
    resource: LCDBitmapPtr
    free: bool
proc `=destroy`(this: var LCDBitmapObj) =
    privateAccess(PlaydateGraphics)
    if this.free:
        playdate.graphics.freeBitmap(this.resource)
type LCDBitmap* = ref LCDBitmapObj

var currentFont: LCDFont

proc setFont*(this: ptr PlaydateGraphics, font: LCDFont) =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    this.setFont(if font != nil: font.resource else: nil)
    currentFont = font

proc getFont*(this: ptr PlaydateGraphics): LCDFont =
    return currentFont

proc pushContext*(this: ptr PlaydateGraphics, target: LCDBitmap) =
    privateAccess(PlaydateGraphics)
    this.pushContext(if target != nil: target.resource else: nil)

proc draw*(this: LCDBitmap, x: int, y: int, flip: LCDBitmapFlip) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.drawBitmap(this.resource, x, y, flip)

proc drawTiled*(this: LCDBitmap, x: int, y: int, width: int, height: int, flip: LCDBitmapFlip) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.tileBitmap(this.resource, x.cint, y.cint, width.cint, height.cint, flip)

proc drawScaled*(this: LCDBitmap, x: int, y: int, xScale: float, yScale: float) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.drawScaledBitmap(this.resource, x.cint, y.cint, xScale.cfloat, yScale.cfloat)

proc drawText*(this: ptr PlaydateGraphics, text: string, x: int, y: int): int {.discardable.} =
    privateAccess(PlaydateGraphics)
    return playdate.graphics.drawText(text.cstring, len(text).csize_t, kASCIIEncoding, x.cint, y.cint).int

proc newBitmap*(this: ptr PlaydateGraphics, width: int, height: int, color: LCDColor): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.newBitmap(width.cint, height.cint, color), free: true)

proc newBitmap*(this: ptr PlaydateGraphics, path: string): LCDBitmap {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    let bitmap = LCDBitmap(resource: this.loadBitmap(path, addr(err)), free: true)
    if bitmap.resource == nil:
        raise newException(IOError, $err)
    return bitmap

proc copy*(this: LCDBitmap): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: playdate.graphics.copyBitmap(this.resource), free: true)

proc load*(this: LCDBitmap, path: string) {.raises: [IOError]}  =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    playdate.graphics.loadIntoBitmap(path.cstring, this.resource, addr(err))
    if err != nil:
        raise newException(IOError, $err)

type BitmapData* = ref object
    width*: int
    height*: int
    bytes*: int

proc getData*(this: LCDBitmap): BitmapData =
    privateAccess(PlaydateGraphics)
    var bitmapData = BitmapData()
    var width, height, bytes: cint
    playdate.graphics.getBitmapData(this.resource, addr(width), addr(height), addr(bytes),
        nil, nil)
    bitmapData.width = width.int
    bitmapData.height = height.int
    bitmapData.bytes = bytes.int
    return bitmapData

proc clear*(this: LCDBitmap, color: LCDColor) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.clearBitmap(this.resource, color)

proc rotated*(this: LCDBitmap, rotation: float, xScale: float, yScale: float):
        tuple[bitmap: LCDBitmap, allocatedSize: int] =
    privateAccess(PlaydateGraphics)
    var allocatedSize: cint
    let bitmap = LCDBitmap(resource: playdate.graphics.rotatedBitmap(this.resource, rotation.cfloat, xScale.cfloat, yScale.cfloat,
        addr(allocatedSize)), free: true)
    return (bitmap, allocatedSize.int)

proc rotated*(this: LCDBitmap, rotation: float, scale: float):
        tuple[bitmap: LCDBitmap, allocatedSize: int] {.inline.} =
    return this.rotated(rotation, scale, scale)

type LCDBitmapTableObj = object
    resource: LCDBitmapTablePtr
proc `=destroy`(this: var LCDBitmapTableObj) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.freeBitmapTable(this.resource)
type LCDBitmapTable* = ref LCDBitmapTableObj

type LCDTableBitmapObj = object of LCDBitmapObj
    table: LCDBitmapTable
proc `=destroy`(this: var LCDTableBitmapObj) =
    privateAccess(PlaydateGraphics)
    this.LCDBitmapObj.`=destroy`()
    this.table = nil
type LCDTableBitmap = ref LCDTableBitmapObj

proc newBitmapTable*(this: ptr PlaydateGraphics, count: int, width: int, height: int): LCDBitmapTable =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDBitmapTable)
    return LCDBitmapTable(resource: this.newBitmapTable(count.cint, width.cint, height.cint))

proc newBitmapTable*(this: ptr PlaydateGraphics, path: string): LCDBitmapTable {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    var bitmapTable = this.loadBitmapTable(path, addr(err))
    if bitmapTable == nil:
        raise newException(IOError, $err)
    return LCDBitmapTable(resource: bitmapTable)

proc load*(this: LCDBitmapTable, path: string) {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    playdate.graphics.loadIntoBitmapTable(path, this.resource, addr(err))
    if err != nil:
        raise newException(IOError, $err)

proc getBitmap*(this: LCDBitmapTable, index: int): LCDBitmap =
    privateAccess(PlaydateGraphics)
    let resource = playdate.graphics.getTableBitmap(this.resource, index.cint)
    if resource != nil:
        return LCDTableBitmap(resource: resource, free: false, table: this)
    return nil

proc newFont*(this: ptr PlaydateGraphics, path: string): LCDFont {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    var err: ConstChar = nil
    var font = this.loadFont(path, addr(err))
    if font == nil:
        raise newException(IOError, $err)
    return LCDFont(resource: font)

proc getFontPage*(this: LCDFont, c: char): LCDFontPage =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    privateAccess(LCDFontPage)
    let fontPage = playdate.graphics.getFontPage(this.resource, c.uint32)
    if fontPage == nil:
        return nil
    return LCDFontPage(resource: fontPage)

proc getPageGlyph*(this: LCDFontPage, c: char): LCDFontGlyph =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFontPage)
    privateAccess(LCDFontGlyph)
    let glyph = playdate.graphics.getPageGlyph(this.resource, c.uint32, nil, nil)
    if glyph == nil:
        return nil
    return LCDFontGlyph(resource: glyph)

proc getGlyphKerning*(this: LCDFontGlyph, glyphCode: char, nextCode: char): int =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFontGlyph)
    return playdate.graphics.getGlyphKerning(this.resource, glyphCode.uint32, nextCode.uint32).int

proc getTextWidth*(this: LCDFont, text: string, len: int, encoding: PDStringEncoding, tracking: int): int =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return playdate.graphics.getTextWidth(this.resource, text.cstring, len.csize_t, encoding, tracking.cint)

type DisplayFrame* = ptr array[LCD_ROWSIZE * LCD_ROWS, uint8]
# type DisplayFrame* = ref DisplayFrameObj

proc getFrame*(this: ptr PlaydateGraphics): DisplayFrame =
    privateAccess(PlaydateGraphics)
    return cast[DisplayFrame](this.getFrame()) # Who should manage this memory? Not clear. Not auto-managed right now.

proc getDisplayFrame*(this: ptr PlaydateGraphics): DisplayFrame =
    privateAccess(PlaydateGraphics)
    return cast[DisplayFrame](this.getDisplayFrame()) # Who should manage this memory? Not clear. Not auto-managed right now.

proc getDebugBitmap*(this: ptr PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getDebugBitmap(), free: true) # Who should manage this memory? Not clear. Auto-managed.

proc copyFrameBufferBitmap*(this: ptr PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.copyFrameBufferBitmap(), free: true)

proc createPattern*(this: ptr PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int): LCDColor =
    privateAccess(PlaydateGraphics)
    var color = 0.LCDColor
    this.setColorToPattern(addr(color), bitmap.resource, x.cint, y.cint)
    return color

import macros

proc fillPolygon*[Int32x2](this: ptr PlaydateGraphics, points: seq[Int32x2], color: LCDColor, fillRule: LCDPolygonFillRule) =
    when sizeof(Int32x2) != sizeof(int32) * 2: {.error: "size of points is not sizeof(int32) * 2".}

    privateAccess(PlaydateGraphics)
    this.fillPolygon(points.len.cint, cast[ptr cint](unsafeAddr(points[0])), color, fillRule)

proc getFontHeight*(this: LCDFont): uint =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return playdate.graphics.getFontHeight(this.resource)

proc getDisplayBufferBitmap*(this: ptr PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getDisplayBufferBitmap(), free: false)

proc drawRotated*(this: LCDBitmap, x: int, y: int, rotation: float, centerX: float, centerY:
        float, xScale: float, yScale: float) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.drawRotatedBitmap(this.resource, x.cint, y.cint, rotation.cfloat, centerX.cfloat, centerY.cfloat,
        xScale.cfloat, yScale.cfloat)

proc setBitmapMask*(this: LCDBitmap, mask: LCDBitmap): int =
    privateAccess(PlaydateGraphics)
    return playdate.graphics.setBitmapMask(this.resource, mask.resource).int

proc getBitmapMask*(this: LCDBitmap): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: playdate.graphics.getBitmapMask(this.resource), free: false) # Who should manage this memory? Not clear. Not auto-managed right now.

proc setStencilImage*(this: ptr PlaydateGraphics, bitmap: LCDBitmap, tile: bool) =
    privateAccess(PlaydateGraphics)
    this.setStencilImage(bitmap.resource, if tile: 1 else: 0)

proc makeFont*(this: LCDFontData, wide: bool): LCDFont =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return LCDFont(resource: playdate.graphics.makeFontFromData(this, if wide: 1 else: 0))
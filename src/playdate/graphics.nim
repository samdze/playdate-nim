{.push raises: [].}

import std/importutils

import bindings/[api, types]
import bindings/graphics {.all.}
export graphics

type LCDBitmapObj = object of RootObj
    resource: LCDBitmapPtr
    free: bool
proc `=destroy`(this: var LCDBitmapObj) =
    privateAccess(PlaydateGraphics)
    if this.free:
        playdate.graphics.freeBitmapRaw(this.resource)
type LCDBitmap* = ref LCDBitmapObj

proc setFont*(this: PlaydateGraphics, font: LCDFont) =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    this.setFontRaw(font.resource)

proc pushContext*(this: PlaydateGraphics, target: LCDBitmap) =
    privateAccess(PlaydateGraphics)
    this.pushContextRaw(if target != nil: target.resource else: nil)

proc drawBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int, flip: LCDBitmapFlip) =
    privateAccess(PlaydateGraphics)
    this.drawBitmapRaw(bitmap.resource, x, y, flip)

proc tileBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int, width: int, height: int, flip: LCDBitmapFlip) =
    privateAccess(PlaydateGraphics)
    this.tileBitmapRaw(bitmap.resource, x.cint, y.cint, width.cint, height.cint, flip)

proc drawScaledBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int, xScale: float, yScale: float) =
    privateAccess(PlaydateGraphics)
    this.drawScaledBitmapRaw(bitmap.resource, x.cint, y.cint, xScale.cfloat, yScale.cfloat)

proc newBitmap*(this: PlaydateGraphics, width: int, height: int, color: LCDColor): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.newBitmapRaw(width.cint, height.cint, color), free: true)

proc loadBitmap*(this: PlaydateGraphics, path: string): LCDBitmap {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    let bitmap = LCDBitmap(resource: this.loadBitmapRaw(path, addr(err)), free: true)
    if bitmap.resource == nil:
        raise newException(IOError, $cast[cstring](err)) # Casting avoids compiler warnings.
    return bitmap

proc copyBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.copyBitmapRaw(bitmap.resource), free: true)

proc loadIntoBitmap*(this: PlaydateGraphics, path: string, bitmap: LCDBitmap) {.raises: [IOError]}  =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    this.loadIntoBitmapRaw(path.cstring, bitmap.resource, addr(err))
    if err != nil:
        raise newException(IOError, $cast[cstring](err)) # Casting avoids compiler warnings.

type BitmapData* = ref object
    width*: int
    height*: int
    bytes*: int

proc getBitmapData*(this: PlaydateGraphics, bitmap: LCDBitmap): BitmapData =
    privateAccess(PlaydateGraphics)
    var bitmapData = BitmapData()
    var width, height, bytes: cint
    this.getBitmapDataRaw(bitmap.resource, addr(width), addr(height), addr(bytes),
        nil, nil)
    bitmapData.width = width.int
    bitmapData.height = height.int
    bitmapData.bytes = bytes.int
    return bitmapData

proc clearBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap, color: LCDColor) =
    privateAccess(PlaydateGraphics)
    this.clearBitmapRaw(bitmap.resource, color)

proc rotatedBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap, rotation: float, xScale: float, yScale: float):
        tuple[bitmap: LCDBitmap, allocatedSize: int] =
    privateAccess(PlaydateGraphics)
    var allocatedSize: cint
    let bitmap = LCDBitmap(resource: this.rotatedBitmapRaw(bitmap.resource, rotation.cfloat, xScale.cfloat, yScale.cfloat,
        addr(allocatedSize)), free: true)
    return (bitmap, allocatedSize.int)

type LCDBitmapTableObj = object
    resource: LCDBitmapTablePtr
proc `=destroy`(this: var LCDBitmapTableObj) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.freeBitmapTableRaw(this.resource)
type LCDBitmapTable* = ref LCDBitmapTableObj

type LCDTableBitmapObj = object of LCDBitmapObj
    table: LCDBitmapTable
proc `=destroy`(this: var LCDTableBitmapObj) =
    privateAccess(PlaydateGraphics)
    this.LCDBitmapObj.`=destroy`()
    this.table = nil
type LCDTableBitmap = ref LCDTableBitmapObj

proc newBitmapTable*(this: PlaydateGraphics, count: int, width: int, height: int): LCDBitmapTable =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDBitmapTable)
    return LCDBitmapTable(resource: this.newBitmapTableRaw(count.cint, width.cint, height.cint))

proc loadBitmapTable*(this: PlaydateGraphics, path: string): LCDBitmapTable {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    var bitmapTable = this.loadBitmapTableRaw(path, addr(err))
    if bitmapTable == nil:
        raise newException(IOError, $cast[cstring](err)) # Casting avoids compiler warnings.
    return LCDBitmapTable(resource: bitmapTable)

proc loadIntoBitmapTable*(this: PlaydateGraphics, path: string, table: LCDBitmapTable) {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    var err: ConstChar = nil
    this.loadIntoBitmapTableRaw(path, table.resource, addr(err))
    if err != nil:
        raise newException(IOError, $cast[cstring](err)) # Casting avoids compiler warnings.

proc getTableBitmap*(this: PlaydateGraphics, table: LCDBitmapTable, index: int): LCDBitmap =
    privateAccess(PlaydateGraphics)
    let resource = this.getTableBitmapRaw(table.resource, index.cint)
    if resource != nil:
        return LCDTableBitmap(resource: resource, free: false, table: table)
    return nil

proc loadFont*(this: PlaydateGraphics, path: string): LCDFont {.raises: [IOError]} =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    var err: ConstChar = nil
    var font = this.loadFontRaw(path, addr(err))
    if font == nil:
        raise newException(IOError, $cast[cstring](err)) # Casting avoids compiler warnings.
    return LCDFont(resource: font)

proc getFontPage*(this: PlaydateGraphics, font: LCDFont, c: char): LCDFontPage =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    privateAccess(LCDFontPage)
    let fontPage = this.getFontPageRaw(font.resource, c.uint32)
    if fontPage == nil:
        return nil
    return LCDFontPage(resource: fontPage)

proc getPageGlyph*(this: PlaydateGraphics, page: LCDFontPage, c: char): LCDFontGlyph =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFontPage)
    privateAccess(LCDFontGlyph)
    let glyph = this.getPageGlyphRaw(page.resource, c.uint32, nil, nil)
    if glyph == nil:
        return nil
    return LCDFontGlyph(resource: glyph)

proc getGlyphKerning*(this: PlaydateGraphics, glyph: LCDFontGlyph, glyphCode: char, nextCode: char): int =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFontGlyph)
    return this.getGlyphKerningRaw(glyph.resource, glyphCode.uint32, nextCode.uint32).int

proc getTextWidth*(this: PlaydateGraphics, font: LCDFont, text: string, len: int, encoding: PDStringEncoding, tracking: int): int =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return this.getTextWidthRaw(font.resource, text.cstring, len.csize_t, encoding, tracking.cint)

type DisplayFrame* = ptr array[LCD_ROWSIZE * LCD_ROWS, uint8]
# type DisplayFrame* = ref DisplayFrameObj

proc getFrame*(this: PlaydateGraphics): DisplayFrame =
    privateAccess(PlaydateGraphics)
    return cast[DisplayFrame](this.getFrameRaw()) # Who should manage this memory? Not clear. Not auto-managed right now.

proc getDisplayFrame*(this: PlaydateGraphics): DisplayFrame =
    privateAccess(PlaydateGraphics)
    return cast[DisplayFrame](this.getDisplayFrameRaw()) # Who should manage this memory? Not clear. Not auto-managed right now.

proc getDebugBitmap*(this: PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getDebugBitmapRaw(), free: true) # Who should manage this memory? Not clear. Auto-managed.

proc copyFrameBufferBitmap*(this: PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.copyFrameBufferBitmapRaw(), free: true)

proc createPattern*(this: PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int): LCDColor =
    privateAccess(PlaydateGraphics)
    var color = 0.LCDColor
    this.setColorToPatternRaw(addr(color), bitmap.resource, x.cint, y.cint)
    return color

import macros

proc fillPolygon*[Int32x2](this: PlaydateGraphics, points: seq[Int32x2], color: LCDColor, fillRule: LCDPolygonFillRule) =
    when sizeof(Int32x2) != sizeof(int32) * 2: {.error: "size of points is not sizeof(int32) * 2".}

    privateAccess(PlaydateGraphics)
    this.fillPolygonRaw(points.len.cint, cast[ptr cint](unsafeAddr(points[0])), color, fillRule)

proc getFontHeight*(this: PlaydateGraphics, font: LCDFont): uint =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return this.getFontHeightRaw(font.resource)

proc getDisplayBufferBitmap*(this: PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getDisplayBufferBitmapRaw(), free: false)

proc drawRotatedBitmap*(this: PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int, rotation: float, centerX: float, centerY:
        float, xScale: float, yScale: float) =
    privateAccess(PlaydateGraphics)
    this.drawRotatedBitmapRaw(bitmap.resource, x.cint, y.cint, rotation.cfloat, centerX.cfloat, centerY.cfloat,
        xScale.cfloat, yScale.cfloat)

proc setBitmapMask*(this: PlaydateGraphics, bitmap: LCDBitmap, mask: LCDBitmap): int =
    privateAccess(PlaydateGraphics)
    return this.setBitmapMaskRaw(bitmap.resource, mask.resource).int

proc getBitmapMask*(this: PlaydateGraphics, bitmap: LCDBitmap): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getBitmapMaskRaw(bitmap.resource), free: false) # Who should manage this memory? Not clear. Not auto-managed right now.

proc setStencilImage*(this: PlaydateGraphics, bitmap: LCDBitmap, tile: bool) =
    privateAccess(PlaydateGraphics)
    this.setStencilImageRaw(bitmap.resource, if tile: 1 else: 0)

proc makeFontFromData*(this: PlaydateGraphics, fontData: LCDFontData, wide: bool): LCDFont =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return LCDFont(resource: this.makeFontFromDataRaw(fontData, if wide: 1 else: 0))
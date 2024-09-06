{.push raises: [].}

import std/importutils

import system
import bindings/[api, types]
import bindings/graphics

# Only export public symbols, then import all
export graphics
{.hint[DuplicateModuleImport]: off.}
import bindings/graphics {.all.}

type LCDBitmapObj = object of RootObj
    resource {.requiresinit.}: LCDBitmapPtr
    free: bool
proc `=destroy`(this: var LCDBitmapObj) =
    privateAccess(PlaydateGraphics)
    if this.free:
        playdate.graphics.freeBitmap(this.resource)
type LCDBitmap* = ref LCDBitmapObj

type LCDVideoPlayerObj = object of RootObj
    resource {.requiresinit.}: LCDVideoPlayerPtr
    context: LCDBitmap
proc `=destroy`(this: var LCDVideoPlayerObj) =
    privateAccess(PlaydateVideo)
    playdate.graphics.video.freePlayer(this.resource)
    this.context = nil
type LCDVideoPlayer* = ref LCDVideoPlayerObj

proc newVideoPlayer*(this: ptr PlaydateVideo, path: string): LCDVideoPlayer {.raises: [IOError]} =
    privateAccess(PlaydateVideo)
    let videoPlayer = this.loadVideo(path.cstring)
    if videoPlayer == nil:
        raise newException(IOError, $this.getError(videoPlayer))
    return LCDVideoPlayer(resource: videoPlayer)

proc setContext*(this: LCDVideoPlayer, context: LCDBitmap) {.raises: [CatchableError]} =
    privateAccess(PlaydateVideo)
    if playdate.graphics.video.setContext(this.resource, if context != nil: context.resource else: nil) == 0:
        raise newException(CatchableError, $playdate.graphics.video.getError(this.resource))
    this.context = context

proc useScreenContext*(this: LCDVideoPlayer) =
    privateAccess(PlaydateVideo)
    playdate.graphics.video.useScreenContext(this.resource)
    this.context = nil

proc renderFrame*(this: LCDVideoPlayer, index: int) {.raises: [CatchableError]} =
    privateAccess(PlaydateVideo)
    if playdate.graphics.video.renderFrame(this.resource, index.cint) == 0:
        raise newException(CatchableError, $playdate.graphics.video.getError(this.resource))

proc getInfo*(this: LCDVideoPlayer): tuple[width: int, height: int, frameRate: float32, frameCount: int, currentFrame: int] =
    privateAccess(PlaydateVideo)
    var width, height, frameCount, currentFrame: cint
    var frameRate: cfloat
    playdate.graphics.video.getInfo(this.resource, addr(width), addr(height), addr(frameRate), addr(frameCount), addr(currentFrame))
    return (width: width.int, height: height.int, frameRate: frameRate.float32, frameCount: frameCount.int, currentFrame: currentFrame.int)

proc getContext*(this: LCDVideoPlayer): LCDBitmap =
    privateAccess(PlaydateVideo)
    let bitmapPtr = playdate.graphics.video.getContext(this.resource)
    playdate.system.logToConsole(fmt"video context: {bitmapPtr.repr}")
    if this.context == nil or this.context.resource != bitmapPtr:
        this.context = LCDBitmap(resource: bitmapPtr, free: false)
    return this.context

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

proc drawScaled*(this: LCDBitmap, x: int, y: int, xScale: float32, yScale: float32) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.drawScaledBitmap(this.resource, x.cint, y.cint, xScale.cfloat, yScale.cfloat)

proc drawText*(
    this: ptr PlaydateGraphics;
    text: string;
    x, y: int;
    encoding: PDStringEncoding = kUTF8Encoding
): int {.discardable.} =
    privateAccess(PlaydateGraphics)
    return playdate.graphics.drawText(text.cstring, len(text).csize_t, encoding, x.cint, y.cint).int

proc newBitmap*(this: ptr PlaydateGraphics, width: int, height: int, color: LCDColor): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.newBitmap(width.cint, height.cint, color.convert), free: true)

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
    rowbytes: int
    data: ptr UncheckedArray[uint8]

proc index(x, y, rowbytes: int): int = y * rowbytes + x div 8
    ## Returns the index of an (x, y) coordinate in a flattened array.

template read(bitmap: BitmapData, x, y: int): untyped =
    ## Read a pixel from a bitmap.
    assert(bitmap.data != nil)
    bitmap.data[index(x, y, bitmap.rowbytes)]

proc getData*(this: LCDBitmap): BitmapData =
    ## Fetch the underlying bitmap data for an image.
    privateAccess(PlaydateGraphics)
    assert(this != nil)
    assert(this.resource != nil)
    var bitmapData = BitmapData()
    playdate.graphics.getBitmapData(
        this.resource,
        cast[ptr cint](addr(bitmapData.width)),
        cast[ptr cint](addr(bitmapData.height)),
        cast[ptr cint](addr(bitmapData.rowbytes)),
        nil,
        cast[ptr ptr uint8](addr(bitmapData.data))
    )
    return bitmapData

proc getSize*(this: LCDBitmap): tuple[width: int, height: int] =
    privateAccess(PlaydateGraphics)
    assert(this != nil)
    assert(this.resource != nil)
    var width, height: cint
    playdate.graphics.getBitmapData(this.resource, addr(width), addr(height), nil,
        nil, nil)
    return (width.int, height.int)

proc clear*(this: LCDBitmap, color: LCDColor) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.clearBitmap(this.resource, color.convert)

proc rotated*(this: LCDBitmap, rotation: float32, xScale: float32, yScale: float32):
        tuple[bitmap: LCDBitmap, allocatedSize: int] =
    privateAccess(PlaydateGraphics)
    var allocatedSize: cint
    let bitmap = LCDBitmap(resource: playdate.graphics.rotatedBitmap(this.resource, rotation.cfloat, xScale.cfloat, yScale.cfloat,
        addr(allocatedSize)), free: true)
    return (bitmap, allocatedSize.int)

proc rotated*(this: LCDBitmap, rotation: float32, scale: float32):
        tuple[bitmap: LCDBitmap, allocatedSize: int] {.inline.} =
    return this.rotated(rotation, scale, scale)

proc tileBitmap*(this: LCDBitmap, x: int, y: int, width: int, height: int, flip: LCDBitmapFlip) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.tileBitmap(this.resource, x.cint, y.cint, width.cint, height.cint, flip)

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

proc getBitmapTableInfo*(this: LCDBitmapTable): tuple[count: int, cellsWide: int] =
    privateAccess(PlaydateGraphics)
    var count, cellsWide: cint
    playdate.graphics.getBitmapTableInfo(this.resource, addr(count), addr(cellsWide))
    return (count.int, cellsWide.int)

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

proc getTextWidth*(
    this: LCDFont,
    text: string,
    len: int = text.len,
    encoding: PDStringEncoding = kUTF8Encoding,
    tracking: int = 0
): int =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return playdate.graphics.getTextWidth(this.resource, text.cstring, len.csize_t, encoding, tracking.cint)

type
    DisplayFrame* = distinct ptr array[LCD_ROWSIZE * LCD_ROWS, uint8]
        ## The raw bytes in a display frame buffer.

    BitmapView* = DisplayFrame | BitmapData
        ## Types that allow the manipulation of individual pixels.

proc getFrame*(this: ptr PlaydateGraphics): DisplayFrame =
    privateAccess(PlaydateGraphics)
    return cast[DisplayFrame](this.getFrame()) # Who should manage this memory? Not clear. Not auto-managed right now.

proc getDisplayFrame*(this: ptr PlaydateGraphics): DisplayFrame =
    privateAccess(PlaydateGraphics)
    return cast[DisplayFrame](this.getDisplayFrame()) # Who should manage this memory? Not clear. Not auto-managed right now.

proc width*(frame: DisplayFrame): auto {.inline.} = LCD_COLUMNS
    ## Return the width of the display frame buffer.

proc height*(frame: DisplayFrame): auto {.inline.} = LCD_ROWS
    ## Return the height of the display frame buffer.

template read(frame: DisplayFrame, x, y: int): untyped =
    ## Read a pixel from a display frame buffer
    assert(cast[pointer](frame) != nil)
    cast[ptr array[LCD_ROWSIZE * LCD_ROWS, uint8]](frame)[index(x, y, LCD_ROWSIZE)]

proc viewBit(x: int): uint8 {.inline.} =
    ## Returns the specific packed bit that is used to represent an `x` coordinate.
    1'u8 shl uint8(7 - (x mod 8))

proc isInView(view: BitmapView, x, y: int): bool {.inline.} =
    ## Returns whether a point is within the frame.
    x >= 0 and y >= 0 and x < view.width and y < view.height

proc get*(view: BitmapView, x, y: int): LCDSolidColor =
    ## Returns the color of a pixel at the given coordinate.
    if not view.isInView(x, y) or (view.read(x, y) and viewBit(x)) != 0:
        kColorWhite
    else:
        kColorBlack

proc set*(view: var BitmapView, x, y: int) =
    ## Sets the pixel at x, y to black.
    if view.isInView(x, y):
        view.read(x, y) = view.read(x, y) and not viewBit(x)

proc clear*(view: var BitmapView, x, y: int) =
    ## Clears the color from a pixel at the given coordinate.
    if view.isInView(x, y):
        view.read(x, y) = view.read(x, y) or viewBit(x)

proc set*(view: var BitmapView, x, y: int, color: LCDSolidColor) =
    ## Sets the specific color of a pixel at the given coordinate.
    if (color == kColorBlack): set(view, x, y) else: clear(view, x, y)

proc getDebugBitmap*(this: ptr PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getDebugBitmap(), free: true) # Who should manage this memory? Not clear. Auto-managed.

proc copyFrameBufferBitmap*(this: ptr PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.copyFrameBufferBitmap(), free: true)

proc createPattern*(this: ptr PlaydateGraphics, bitmap: LCDBitmap, x: int, y: int): LCDPattern =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDPattern)
    var color = new(LCDPattern)
    this.setColorToPattern(addr color.pattern, bitmap.resource, x.cint, y.cint)
    return color

import macros

proc fillPolygon*[Int32x2](this: ptr PlaydateGraphics, points: seq[Int32x2], color: LCDColor, fillRule: LCDPolygonFillRule) =
    when sizeof(Int32x2) != sizeof(int32) * 2: {.error: "size of points is not sizeof(int32) * 2".}

    privateAccess(PlaydateGraphics)
    this.fillPolygon(points.len.cint, cast[ptr cint](unsafeAddr(points[0])), color.convert, fillRule)

proc getFontHeight*(this: LCDFont): uint =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return playdate.graphics.getFontHeight(this.resource)

proc getDisplayBufferBitmap*(this: ptr PlaydateGraphics): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: this.getDisplayBufferBitmap(), free: false)

proc drawRotated*(this: LCDBitmap, x: int, y: int, rotation: float32, centerX: float32, centerY:
        float32, xScale: float32, yScale: float32) =
    privateAccess(PlaydateGraphics)
    playdate.graphics.drawRotatedBitmap(this.resource, x.cint, y.cint, rotation.cfloat, centerX.cfloat, centerY.cfloat,
        xScale.cfloat, yScale.cfloat)

proc width*(this: LCDBitmap): int = this.getData.width

proc height*(this: LCDBitmap): int = this.getData.height

proc setBitmapMask*(
    this: LCDBitmap,
    mask: LCDBitmap = playdate.graphics.newBitmap(this.width, this.height, kColorWhite)
): int =
    privateAccess(PlaydateGraphics)
    return playdate.graphics.setBitmapMask(this.resource, mask.resource).int

proc getBitmapMask*(this: LCDBitmap): LCDBitmap =
    privateAccess(PlaydateGraphics)
    return LCDBitmap(resource: playdate.graphics.getBitmapMask(this.resource), free: false) # Who should manage this memory? Not clear. Not auto-managed right now.

proc get*(this: LCDBitmap, x, y: int): LCDSolidColor =
    ## Reads the color of a bitmap, taking into account the color mask
    if this.getBitmapMask.resource != nil and this.getBitmapMask.getData.get(x, y) == kColorBlack:
        return kColorClear
    else:
        return this.getData.get(x, y)

proc set*(this: var LCDBitmap, x, y: int, color: LCDSolidColor = kColorBlack) =
    ## Reads the color of a bitmap, taking into account the color mask
    if color == kColorClear:
        var mask = this.getBitmapMask.getData
        mask.set(x, y, kColorBlack)
    else:
        if this.getBitmapMask.resource != nil:
            var mask = this.getBitmapMask.getData
            mask.set(x, y, kColorWhite)
        var data = this.getData
        data.set(x, y, color)

proc setStencilImage*(this: ptr PlaydateGraphics, bitmap: LCDBitmap, tile: bool) =
    privateAccess(PlaydateGraphics)
    this.setStencilImage(bitmap.resource, if tile: 1 else: 0)

proc makeFont*(this: LCDFontData, wide: bool): LCDFont =
    privateAccess(PlaydateGraphics)
    privateAccess(LCDFont)
    return LCDFont(resource: playdate.graphics.makeFontFromData(this, if wide: 1 else: 0))

proc `$`*(view: BitmapView | LCDBitmap): string =
    ## Render a string version of a bitmap view
    for y in 0..<view.height:
        for x in 0..<view.width:
            case view.get(x, y)
            of kColorBlack: result.add("█")
            of kColorWhite: result.add("░")
            of kColorClear: result.add(" ")
            of kColorXOR: result.add("X")
        result.add("\n")

import strutils
import std/strbasics

proc getTextSize*(this: LCDFont, text: string, lineHeightAdjustment: int = 0): tuple[width: int, height: int] =
    let lineHeight = this.getFontHeight().int + lineHeightAdjustment
    let lines = text.splitLines(false)
    let height = lines.len * lineHeight
    var width = 0

    for line in lines:
        width = max(this.getTextWidth(line), width)
    
    return (width, height)

type TextAlignment* = enum
    kTextAlignmentLeft, kTextAlignmentCenter, kTextAlignmentRight

proc drawTextAligned*(this: ptr PlaydateGraphics, text: string, x, y: int,
        alignment: TextAlignment = kTextAlignmentCenter, lineHeightAdjustment: int = 0) =
    assert(this.getFont() != nil)

    let font = this.getFont()
    var drawX = x
    var drawY = y
    let lineHeight = font.getFontHeight().int + lineHeightAdjustment #+ this.getTextLeading() # missing function

    for line in text.splitLines(false):
        let lineWidth = font.getTextWidth(line)

        case alignment:
        of kTextAlignmentRight:
            drawX = x - lineWidth
        of kTextAlignmentCenter:
            drawX = x - (lineWidth / 2).int
        else: discard

        playdate.graphics.drawText(line, drawX, drawY)
        drawY += lineHeight

proc drawTextAligned*(this: LCDFont, text: string, x, y: int,
        alignment: TextAlignment = kTextAlignmentCenter, lineHeightAdjustment: int = 0) =
    let previousFont = playdate.graphics.getFont()
    playdate.graphics.setFont(this)
    playdate.graphics.drawTextAligned(text, x, y, alignment, lineHeightAdjustment)
    playdate.graphics.setFont(previousFont)

type TextInRectResult* = object
    width*: int
    height*: int
    textWasTruncated*: bool

proc layoutTextInRect(this: LCDFont, text: string, x, y, width, height: int,
    lineHeightAdjustment: int = 0, truncationString: string = "...",
    alignment: TextAlignment = kTextAlignmentLeft, draw: bool = true
): TextInRectResult {.discardable.} =
    
    if text.len == 0:
        return

    # From now on, a premature return means the text has been truncated.
    result.textWasTruncated = true
    if width <= 0 or height <= 0:
        return
    
    let fontHeight = this.getFontHeight().int
    let lineHeight = fontHeight + lineHeightAdjustment

    if height < fontHeight:
        return
    
    let truncationWidth = this.getTextWidth(truncationString)
    let textWidth = this.getTextWidth(text)
    if width < textWidth and width < truncationWidth:
        return

    let bottom = y + height
    let lines = text.splitLines(false)
    var maxLineWidth = 0
    var drawY = y - lineHeight

    # There will be many strings manipulations, allocate space to perform them in place.
    var maxLineLenght = 0
    for line in lines:
        maxLineLenght = max(maxLineLenght, line.len)
    maxLineLenght += truncationString.len

    proc drawAlignedLine(line: var string) =
        ## Draws an aligned line.
        strbasics.strip(line, false, true)
        let lineWidth = this.getTextWidth(line)
        maxLineWidth = max(maxLineWidth, lineWidth)

        if not draw:
            return
        var drawX = x
        case alignment:
        of kTextAlignmentRight:
            drawX = x + width - lineWidth
        of kTextAlignmentCenter:
            drawX = x + ((width - lineWidth) / 2).int
        else: discard

        playdate.graphics.drawText(line, drawX, drawY)

    proc drawTruncatedWord(word: string): string =
        ## Draws a line with a word until there's horizontal space.
        ## Returns the remaining piece of the word left to draw.
        var lineWidth = this.getTextWidth(word)
        var truncatedWord = word

        while lineWidth > width and truncatedWord.len > 0:
            # Remove the last character from the word and retry.
            truncatedWord.delete(truncatedWord.len - 1 .. truncatedWord.len - 1)
            lineWidth = this.getTextWidth(truncatedWord)

        drawAlignedLine(truncatedWord)
        # Return the remaining word.
        return word.substr(truncatedWord.len)
    
    proc drawTruncatedLine(line: var string) =
        line.add(truncationString)

        while this.getTextWidth(line) > width and (line.len - truncationString.len) > 0:
            line.delete((line.len - truncationString.len - 1)..<line.len)
            line.add(truncationString)
        
        drawAlignedLine(line)

    var currentLine = newStringOfCap(maxLineLenght)
    var firstWordInLine = true
    var truncated = false
    block main:
        for line in lines:
            drawY += lineHeight
            firstWordInLine = true
            # Reset the current line to an empty string.
            if currentLine.len > 0: currentLine.delete(0..<currentLine.len)

            for token in line.tokenize():
                currentLine.add(token.token)

                if this.getTextWidth(currentLine) <= width:
                    firstWordInLine = false
                else:
                    while this.getTextWidth(currentLine) > width:

                        let lastLine = (drawY + lineHeight + fontHeight) > bottom

                        if lastLine:
                            # There is not vertical space left, truncate the line and break.
                            drawTruncatedLine(currentLine)
                            truncated = true
                            break main
                        # If this is the first word of the line, break it, otherwise just go to the next line.
                        elif firstWordInLine:
                            if token.isSep:
                                # Reset the current line if the word is just whitespaces.
                                if currentLine.len > 0: currentLine.delete(0..<currentLine.len)
                            else:
                                let remainingWord = drawTruncatedWord(currentLine)
                                if currentLine.len > 0: currentLine.delete(0..<currentLine.len)
                                currentLine.add(remainingWord)
                            # Go to the next line.
                            drawY += lineHeight
                        else:
                            let word = token.token
                            # Normal line break, draw currentLine without the last word.
                            # currentLine.setSlice(0..<(currentLine.len - word.len))
                            currentLine.delete((currentLine.len - word.len)..<currentLine.len)

                            drawAlignedLine(currentLine)
                            drawY += lineHeight

                            if currentLine.len > 0: currentLine.delete(0..<currentLine.len)
                            if not token.isSep:
                                currentLine.add(word)
                            # We're at the first word in the line again.
                            firstWordInLine = true
                    
                    if not token.isSep:
                        firstWordInLine = false

            if not currentLine.isEmptyOrWhitespace():
                drawAlignedLine(currentLine)
    
    return TextInRectResult(width: maxLineWidth, height: drawY - y + fontHeight, textWasTruncated: truncated)

proc drawTextInRect*(this: LCDFont, text: string, x, y, width, height: int,
    lineHeightAdjustment: int = 0, truncationString: string = "...", alignment: TextAlignment = kTextAlignmentLeft
): TextInRectResult {.discardable.} =
    let previousFont: LCDFont = playdate.graphics.getFont()
    playdate.graphics.setFont(this)
    
    result = layoutTextInRect(this, text, x, y, width, height, lineHeightAdjustment, truncationString, alignment, true)

    playdate.graphics.setFont(previousFont)

proc getTextSizeInRect*(this: LCDFont, text: string, x, y, width, height: int,
    lineHeightAdjustment: int = 0, truncationString: string = "...", alignment: TextAlignment = kTextAlignmentLeft
): TextInRectResult =
    
    return layoutTextInRect(this, text, x, y, width, height, lineHeightAdjustment, truncationString, alignment, false)

proc drawTextInRect*(this: ptr PlaydateGraphics, text: string, x, y, width, height: int,
    lineHeightAdjustment: int = 0, truncationString: string = "...", alignment: TextAlignment = kTextAlignmentLeft
): TextInRectResult {.discardable.} =
    assert(this.getFont() != nil)

    return layoutTextInRect(this.getFont(), text, x, y, width, height, lineHeightAdjustment, truncationString, alignment, true)

proc getTextSizeInRect*(this: ptr PlaydateGraphics, text: string, x, y, width, height: int,
    lineHeightAdjustment: int = 0, truncationString: string = "...", alignment: TextAlignment = kTextAlignmentLeft
): TextInRectResult =
    assert(this.getFont() != nil)

    return layoutTextInRect(this.getFont(), text, x, y, width, height, lineHeightAdjustment, truncationString, alignment, false)
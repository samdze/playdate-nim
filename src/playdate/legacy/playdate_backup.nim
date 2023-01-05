type PDCallbackFunction* {.importc: "PDCallbackFunction", header: "pd_api/pd_api_sys.h".} = proc(userdata: pointer): cint {.cdecl.}

type PlaydateSysRaw {.importc: "playdate_sys", header: "pd_api/pd_api_sys.h".} = object
    drawFPS* {.importc: "drawFPS".}: proc (x: cint; y: cint) {.cdecl.}
    # setUpdateCallback* {.importc: "setUpdateCallback".}: proc (
    #     update: proc (userdata: pointer): cint, userdata: pointer) {.cdecl.}
    setUpdateCallback*: proc (update: PDCallbackFunction, userdata: pointer) {.cdecl.}
    logToConsole* {.importc.}: proc (fmt: cstring) {.cdecl, varargs.}
    error* {.importc.}: proc (fmt: cstring) {.cdecl, varargs.}
type PlaydateSys* = ptr PlaydateSysRaw

# type LCDBitmapDrawMode* {.size: sizeof(cint).} = enum
# type LCDBitmapDrawMode* {.importc: "LCDBitmapDrawMode", header: "pd_api/pd_api_gfx.h".} = enum
#     kDrawModeCopy, kDrawModeWhiteTransparent, kDrawModeBlackTransparent,
#     kDrawModeFillWhite, kDrawModeFillBlack, kDrawModeXOR, kDrawModeNXOR,
#     kDrawModeInverted
# type LCDBitmapFlip* {.size: sizeof(cint).} = enum
# type LCDBitmapFlip* {.importc: "LCDBitmapFlip", header: "pd_api/pd_api_gfx.h".} = enum
#     kBitmapUnflipped, kBitmapFlippedX, kBitmapFlippedY, kBitmapFlippedXY
# type LCDSolidColor {.size: sizeof(cint).} = enum
type LCDSolidColor* {.importc: "LCDSolidColor", header: "pd_api/pd_api_gfx.h".} = enum
    kColorBlack, kColorWhite, kColorClear, kColorXOR
# type LCDLineCapStyle* {.size: sizeof(cint).} = enum
# type LCDLineCapStyle* {.importc: "LCDLineCapStyle", header: "pd_api/pd_api_gfx.h".} = enum
#     kLineCapStyleButt, kLineCapStyleSquare, kLineCapStyleRound
# type LCDFontLanguage* {.size: sizeof(cint).} = enum
# type LCDFontLanguage* {.importc: "LCDFontLanguage", header: "pd_api/pd_api_gfx.h".} = enum
#     kLCDFontLanguageEnglish, kLCDFontLanguageJapanese, kLCDFontLanguageUnknown
# type PDStringEncoding* {.size: sizeof(cint).} = enum
type PDStringEncoding* {.importc: "PDStringEncoding", header: "pd_api/pd_api_gfx.h".} = enum
    kASCIIEncoding, kUTF8Encoding, k16BitLEEncoding
type LCDPattern* = array[16, cuint]

# type LCDFont* {.importc: "LCDFont", header: "pd_api/pd_api_gfx.h".} = object
type LCDFontRaw {.importc: "LCDFont", header: "pd_api/pd_api_gfx.h", bycopy.} = object
type LCDFont* = ptr LCDFontRaw
type LCDColor* {.importc: "LCDColor", header: "pd_api/pd_api_gfx.h", nodecl.} = cuint

type PlaydateGraphicsRaw {.importc: "struct playdate_graphics", header: "pd_api/pd_api_gfx.h", bycopy.} = object
    # video* {.importc: "video".}: ptr PlaydateVideo ##  Drawing Functions
    clear* {.importc: "clear".}: proc (color: LCDColor) {.cdecl.}
    setFont* {.importc: "setFont".}: proc (font: LCDFont) {.cdecl.}
    drawTextRaw {.importc: "drawText".}: proc (text: cstring; len: csize_t;
        encoding: PDStringEncoding; x: cint; y: cint): cint {.cdecl.}
    # drawText*: proc (text: string; len: uint; encoding: PDStringEncoding; x: int; y: int): int
    loadFontRaw {.importc: "loadFont".}: proc (path: cstring; outErr: ptr cstring): LCDFont {.cdecl.}

# Nim object with utility procedures.
type PlaydateGraphics* = ptr PlaydateGraphicsRaw

proc drawText*(this: PlaydateGraphics, text: string, len: uint, encoding: PDStringEncoding, x: int, y: int): int =
    return int(this.drawTextRaw(text.cstring, len.csize_t, encoding, x.cint, y.cint))

proc loadFont*(this: PlaydateGraphics, path: string): (LCDFont, string) =
    type constChar {.importc: "const char*".} = cstring
    var err: constChar = nil
    var font = this.loadFontRaw(path, addr(err))
    return (font, $cast[cstring](err)) # Casting avoids the compiler warning.


type LCDRect* = object
    left* {.importc.}: int
    right* {.importc.}: int
    top* {.importc.}: int
    bottom* {.importc.}: int

proc LCDMakeRect(x: int, y: int, width: int, height: int): LCDRect =
    return LCDRect(left: x, right: x + width, top: y, bottom: y + height)

proc LCDRect_translate*(rect: LCDRect, dx: int, dy: int): LCDRect {.importc: "PDStringEncoding", header: "pd_api/pd_api_gfx.h".}
    # return LCDRect(left: x, right: x + width, top: y, bottom: y + height)

const LCD_COLUMNS*: int = 400
const LCD_ROWS*: int = 240
const LCD_ROWSIZE*: int = 52
const LCD_SCREEN_RECT* = LCDMakeRect(0, 0, LCD_COLUMNS, LCD_ROWS)

type PlaydateAPIRaw {.importc: "PlaydateAPI", header: "pd_api.h", bycopy.} = object
    system* {.importc: "system".}: PlaydateSys
    graphics* {.importc: "graphics".}: PlaydateGraphics
type PlaydateAPI* = ptr PlaydateAPIRaw


# type PDSystemEvent* {.size: sizeof(cint).} = enum
type PDSystemEvent* {.importc: "PDSystemEvent", header: "pd_api.h".} = enum
    kEventInit, kEventInitLua, kEventLock, kEventUnlock, kEventPause, kEventResume,
    kEventTerminate, kEventKeyPressed, ##  arg is keycode
    kEventKeyReleased, kEventLowPower
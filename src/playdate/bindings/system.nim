{.push raises: [].}

import utils
import types

type PDButton* {.importc: "PDButtons", header: "pd_api.h", size: sizeof(uint32).} = enum
    kButtonLeft = (1 shl 0), kButtonRight = (1 shl 1), kButtonUp = (1 shl 2),
    kButtonDown = (1 shl 3), kButtonB = (1 shl 4), kButtonA = (1 shl 5)
type PDButtons* = set[PDButton]
proc check*(this: PDButtons, button: PDButton): bool =
    return (cast[uint32](this) and cast[uint32](button)) != 0

type PDLanguage* {.importc: "PDLanguage", header: "pd_api.h".} = enum
    kPDLanguageEnglish, kPDLanguageJapanese, kPDLanguageUnknown

type PDMenuItemPtr {.importc: "PDMenuItem*", header: "pd_api.h".} = pointer
type
    PDMenuItem* = ref object of RootObj
        resource: PDMenuItemPtr
        active: bool
    PDMenuItemButton* = ref object of PDMenuItem
        callback*: proc(menuItem: PDMenuItemButton) {.raises: [].}
    PDMenuItemCheckmark* = ref object of PDMenuItem
        callback*: proc(menuItem: PDMenuItemCheckmark) {.raises: [].}
    PDMenuItemOptions* = ref object of PDMenuItem
        callback*: proc(menuItem: PDMenuItemOptions) {.raises: [].}

type PDPeripherals* {.importc: "PDPeripherals", header: "pd_api.h".} = enum
    kNone = 0, kAccelerometer = (1 shl 0), kAllPeripherals = 0xffff

type PDCallbackFunctionRaw {.importc: "PDCallbackFunction", header: "pd_api.h".} = proc(userdata: pointer): cint {.cdecl.}

type PDMenuItemCallbackFunctionRaw {.importc: "PDMenuItemCallbackFunction", header: "pd_api.h".} = proc(userdata: pointer) {.cdecl.}

# System
sdktype PlaydateSys:
    type PlaydateSys {.importc: "const struct playdate_sys", header: "pd_api.h".} = object
        realloc {.importc: "realloc".}: proc (`ptr`: pointer; size: csize_t): pointer {.
            cdecl, raises: [].}
        formatString {.importc: "formatString".}: proc (ret: cstringArray; fmt: cstring): cint {.
            cdecl, varargs, raises: [].}
        logToConsoleRaw {.importc: "logToConsole".}: proc (fmt: cstring) {.cdecl, varargs, raises: [].}
        errorRaw {.importc: "error".}: proc (fmt: cstring) {.cdecl, varargs, raises: [].}
        getLanguage {.importsdk.}: proc (): PDLanguage
        getCurrentTimeMillisecondsRaw {.importsdk.}: proc (): cuint
        getSecondsSinceEpochRaw {.importc: "getSecondsSinceEpoch".}: proc (milliseconds: ptr cuint): cuint {.cdecl, raises: [].}
        drawFPS {.importsdk.}: proc (x: cint; y: cint)
        setUpdateCallbackRaw {.importc: "setUpdateCallback".}: proc (update: PDCallbackFunctionRaw, userdata: pointer) {.cdecl, raises: [].}
        getButtonStateRaw {.importc: "getButtonState".}: proc (current: ptr PDButton;
            pushed: ptr PDButton; released: ptr PDButton) {.cdecl, raises: [].}
        setPeripheralsEnabled* {.importc.}: proc (mask: PDPeripherals) {.cdecl, raises: [].}
        getAccelerometerRaw {.importc: "getAccelerometer".}: proc (outx: ptr cfloat;
            outy: ptr cfloat; outz: ptr cfloat) {.cdecl, raises: [].}
        getCrankChange {.importsdk.}: proc (): cfloat
        getCrankAngle {.importsdk.}: proc (): cfloat
        isCrankDockedRaw {.importc: "isCrankDocked".}: proc (): cint {.cdecl, raises: [].}
        setCrankSoundsDisabledRaw {.importc: "setCrankSoundsDisabled".}: proc (flag: cint): cint {.
            cdecl, raises: [].}               ##  returns previous setting
        getFlippedRaw {.importc: "getFlipped".}: proc (): cint {.cdecl, raises: [].}
        setAutoLockDisabledRaw {.importc: "setAutoLockDisabled".}: proc (disable: cint) {.
            cdecl, raises: [].}
        
        setMenuImage {.importsdk.}: proc (bitmap: LCDBitmapPtr;
            xOffset: cint)
        addMenuItemRaw {.importc: "addMenuItem".}: proc (title: cstring;
            callback: PDMenuItemCallbackFunctionRaw; userdata: pointer): PDMenuItemPtr {.
            cdecl, raises: [].}
        addCheckmarkMenuItemRaw {.importc: "addCheckmarkMenuItem".}: proc (title: cstring;
            value: cint; callback: PDMenuItemCallbackFunctionRaw; userdata: pointer): PDMenuItemPtr {.
            cdecl, raises: [].}
        addOptionsMenuItemRaw {.importc: "addOptionsMenuItem".}: proc (title: cstring;
            optionTitles: ConstCharPtr; optionsCount: cint;
            f: PDMenuItemCallbackFunctionRaw; userdata: pointer): PDMenuItemPtr {.cdecl, raises: [].}
        removeAllMenuItemsRaw {.importc: "removeAllMenuItems".}: proc () {.cdecl, raises: [].}
        removeMenuItemRaw {.importc: "removeMenuItem".}: proc (menuItem: PDMenuItemPtr) {.
            cdecl, raises: [].}
        getMenuItemValueRaw {.importc: "getMenuItemValue".}: proc (
            menuItem: PDMenuItemPtr): cint {.cdecl, raises: [].}
        setMenuItemValueRaw {.importc: "setMenuItemValue".}: proc (
            menuItem: PDMenuItemPtr; value: cint) {.cdecl, raises: [].}
        getMenuItemTitleRaw {.importc: "getMenuItemTitle".}: proc (
            menuItem: PDMenuItemPtr): ConstChar {.cdecl, raises: [].}
        setMenuItemTitleRaw {.importc: "setMenuItemTitle".}: proc (
            menuItem: PDMenuItemPtr; title: cstring) {.cdecl, raises: [].}
        getMenuItemUserdataRaw {.importc: "getMenuItemUserdata".}: proc (
            menuItem: PDMenuItemPtr): pointer {.cdecl, raises: [].}
        setMenuItemUserdataRaw {.importc: "setMenuItemUserdata".}: proc (
            menuItem: PDMenuItemPtr; ud: pointer) {.cdecl, raises: [].}
        
        getReduceFlashingRaw {.importc: "getReduceFlashing".}: proc (): cint {.cdecl, raises: [].} ##  1.1
        getElapsedTime {.importsdk.}: proc (): cfloat
        resetElapsedTime* {.importc: "resetElapsedTime".}: proc () {.cdecl, raises: [].} ##  1.4
        getBatteryPercentage {.importsdk.}: proc (): cfloat
        getBatteryVoltage {.importsdk.}: proc (): cfloat
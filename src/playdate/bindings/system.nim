{.push raises: [].}

import utils
import types

type PDButton* {.importc: "PDButtons", header: "pd_api.h", size: sizeof(uint32).} = enum
    kButtonLeft = 1, kButtonRight = 2, kButtonUp = 3,
    kButtonDown = 4, kButtonB = 5, kButtonA = 6

type PDButtons* = set[PDButton]

type PDLanguage* {.importc: "PDLanguage", header: "pd_api.h".} = enum
    kPDLanguageEnglish, kPDLanguageJapanese, kPDLanguageUnknown

type PDMenuItemPtr {.importc: "PDMenuItem*", header: "pd_api.h".} = pointer
type
    PDMenuItem* = ref object of RootObj
        resource: PDMenuItemPtr
        active {.requiresinit.}: bool
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
sdktype:
    type PlaydateSys* {.importc: "const struct playdate_sys", header: "pd_api.h".} = object
        realloc {.importc: "realloc".}: PDRealloc
        formatString {.importc: "formatString".}: proc (ret: cstringArray; fmt: cstring): cint {.
            cdecl, varargs, raises: [].}
        logToConsole {.importc: "logToConsole".}: PDLog
        error {.importc: "error".}: proc (fmt: cstring) {.cdecl, varargs, raises: [].}
        getLanguage {.importsdk.}: proc (): PDLanguage
        getCurrentTimeMilliseconds {.importsdk.}: proc (): cuint
        getSecondsSinceEpoch {.importc: "getSecondsSinceEpoch".}: proc (milliseconds: ptr cuint): cuint {.cdecl, raises: [].}
        drawFPS {.importsdk.}: proc (x: cint; y: cint)
        setUpdateCallback {.importc: "setUpdateCallback".}: proc (update: PDCallbackFunctionRaw, userdata: pointer) {.cdecl, raises: [].}
        getButtonState {.importc: "getButtonState".}: proc (current: ptr PDButton;
            pushed: ptr PDButton; released: ptr PDButton) {.cdecl, raises: [].}
        setPeripheralsEnabled* {.importc.}: proc (mask: PDPeripherals) {.cdecl, raises: [].}
        getAccelerometer {.importc: "getAccelerometer".}: proc (outx: ptr cfloat;
            outy: ptr cfloat; outz: ptr cfloat) {.cdecl, raises: [].}
        getCrankChange {.importsdk.}: proc (): cfloat
        getCrankAngle {.importsdk.}: proc (): cfloat
        isCrankDocked {.importc: "isCrankDocked".}: proc (): cint {.cdecl, raises: [].}
        setCrankSoundsDisabled {.importc: "setCrankSoundsDisabled".}: proc (flag: cint): cint {.
            cdecl, raises: [].}               ##  returns previous setting
        getFlipped {.importc: "getFlipped".}: proc (): cint {.cdecl, raises: [].}
        setAutoLockDisabled {.importc: "setAutoLockDisabled".}: proc (disable: cint) {.
            cdecl, raises: [].}
        
        setMenuImage {.importc: "setMenuImage".}: proc (bitmap: LCDBitmapPtr;
            xOffset: cint) {.cdecl, raises: [].}
        addMenuItem {.importc: "addMenuItem".}: proc (title: cstring;
            callback: PDMenuItemCallbackFunctionRaw; userdata: pointer): PDMenuItemPtr {.
            cdecl, raises: [].}
        addCheckmarkMenuItem {.importc: "addCheckmarkMenuItem".}: proc (title: cstring;
            value: cint; callback: PDMenuItemCallbackFunctionRaw; userdata: pointer): PDMenuItemPtr {.
            cdecl, raises: [].}
        addOptionsMenuItem {.importc: "addOptionsMenuItem".}: proc (title: cstring;
            optionTitles: ConstCharPtr; optionsCount: cint;
            f: PDMenuItemCallbackFunctionRaw; userdata: pointer): PDMenuItemPtr {.cdecl, raises: [].}
        removeAllMenuItems {.importc: "removeAllMenuItems".}: proc () {.cdecl, raises: [].}
        removeMenuItem {.importc: "removeMenuItem".}: proc (menuItem: PDMenuItemPtr) {.
            cdecl, raises: [].}
        getMenuItemValue {.importc: "getMenuItemValue".}: proc (
            menuItem: PDMenuItemPtr): cint {.cdecl, raises: [].}
        setMenuItemValue {.importc: "setMenuItemValue".}: proc (
            menuItem: PDMenuItemPtr; value: cint) {.cdecl, raises: [].}
        getMenuItemTitle {.importc: "getMenuItemTitle".}: proc (
            menuItem: PDMenuItemPtr): ConstChar {.cdecl, raises: [].}
        setMenuItemTitle {.importc: "setMenuItemTitle".}: proc (
            menuItem: PDMenuItemPtr; title: cstring) {.cdecl, raises: [].}
        getMenuItemUserdata {.importc: "getMenuItemUserdata".}: proc (
            menuItem: PDMenuItemPtr): pointer {.cdecl, raises: [].}
        setMenuItemUserdata {.importc: "setMenuItemUserdata".}: proc (
            menuItem: PDMenuItemPtr; ud: pointer) {.cdecl, raises: [].}
        
        getReduceFlashing {.importc: "getReduceFlashing".}: proc (): cint {.cdecl, raises: [].} ##  1.1
        getElapsedTime {.importsdk.}: proc (): cfloat
        resetElapsedTime* {.importc: "resetElapsedTime".}: proc () {.cdecl, raises: [].} ##  1.4
        getBatteryPercentage {.importsdk.}: proc (): cfloat
        getBatteryVoltage {.importsdk.}: proc (): cfloat
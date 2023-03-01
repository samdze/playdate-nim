{.push raises: [].}

import std/importutils
import strformat
import sequtils

import bindings/[api, types, utils]
import bindings/system

# Only export public symbols, then import all
export system
{.hint[DuplicateModuleImport]: off.}
import bindings/system {.all.}

template fmt*(arg: typed): string =
    try: &(arg) except: arg

proc logToConsole*(this: ptr PlaydateSys, str: string) {.wrapApi(PlaydateSys).}

proc error*(this: ptr PlaydateSys, str: string) {.wrapApi(PlaydateSys).}

proc getSecondsSinceEpoch* (this: ptr PlaydateSys): tuple[seconds: uint, milliseconds: uint] =
    privateAccess(PlaydateSys)
    var ms: cuint
    let sec = this.getSecondsSinceEpoch(addr(ms)).uint
    return (seconds: sec, milliseconds: ms.uint)

# --- Update function
type PDCallbackFunction* = proc(): int {.raises: [].}
var updateCallback: PDCallbackFunction = nil

proc privateUpdate(userdata: pointer): cint {.cdecl.} =
    if updateCallback != nil:
        return updateCallback().cint
    else:
        playdate.system.error("No update callback defined.")
        return 0

proc setUpdateCallback*(this: ptr PlaydateSys, update: PDCallbackFunction) =
    privateAccess(PlaydateSys)
    updateCallback = update
    this.setUpdateCallback(privateUpdate, playdate)
# ---

proc getButtonsState* (this: ptr PlaydateSys): tuple[current: PDButtons, pushed: PDButtons, released: PDButtons] =
    privateAccess(PlaydateSys)
    var current, pushed, released: uint32
    this.getButtonState(addr(current), addr(pushed), addr(released))
    return (current: cast[PDButtons](current), pushed: cast[PDButtons](pushed), released: cast[PDButtons](released))

proc getAccelerometer* (this: ptr PlaydateSys): tuple[x: float, y: float, z: float] =
    privateAccess(PlaydateSys)
    var x, y, z: cfloat
    this.getAccelerometer(addr(x), addr(y), addr(z))
    return (x: x.float, y: y.float, z: z.float)

proc isCrankDocked* (this: ptr PlaydateSys): bool {.wrapApi(PlaydateSys).}

proc setCrankSoundsEnabled* (this: ptr PlaydateSys, enabled: bool): bool {.wrapApi(PlaydateSys, setCrankSoundsDisabled).}
    ## returns previous setting

proc getFlipped* (this: ptr PlaydateSys): bool {.wrapApi(PlaydateSys).}

proc setAutoLockEnabled* (this: ptr PlaydateSys, enabled: bool) {.wrapApi(PlaydateSys, setAutoLockDisabled).}

# --- Menu items
privateAccess(PDMenuItem)
var menuItems = newSeq[PDMenuItem](0)

func isActive*(this: PDMenuItem): bool =
    privateAccess(PDMenuItem)
    return this.active

proc `title=`*(this: PDMenuItem, title: string) {.wrapApi(PlaydateSys, setMenuItemTitle).}

proc title*(this: PDMenuItem): string {.wrapApi(PlaydateSys, getMenuItemTitle).}

proc remove*(this: PDMenuItem) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    if this.active:
        this.active = false
        playdate.system.removeMenuItem(this.resource)
        for i in countdown(menuItems.len - 1, 0):
            if menuItems[i] == this:
                menuItems.del(i)
                return

# Useful when there are cicrular references between the callback and the menu item.
# But it should never happen.
# proc remove*(this: PDMenuItemButton|PDMenuItemCheckmark|PDMenuItemOptions) =
#     this.callback = nil
#     this.PDMenuItem.remove()

proc `value=`*(this: PDMenuItemCheckmark, checked: bool) {.wrapApi(PlaydateSys, setMenuItemValue).}

proc value*(this: PDMenuItemCheckmark): bool {.wrapApi(PlaydateSys, getMenuItemValue).}

proc `value=`*(this: PDMenuItemOptions, index: int) {.wrapApi(PlaydateSys, setMenuItemValue).}

proc value*(this: PDMenuItemOptions): int {.wrapApi(PlaydateSys, getMenuItemValue).}

type PDMenuItemButtonCallbackFunction* = proc(menuItem: PDMenuItemButton) {.raises: [].}
type PDMenuItemCheckmarkCallbackFunction* = proc(menuItem: PDMenuItemCheckmark) {.raises: [].}
type PDMenuItemOptionsCallbackFunction* = proc(menuItem: PDMenuItemOptions) {.raises: [].}

proc privateMenuItemButtonCallback(userdata: pointer) {.cdecl.} =
    let menuItem = cast[PDMenuItemButton](userdata)
    menuItem.callback(menuItem)

proc privateMenuItemCheckmarkCallback(userdata: pointer) {.cdecl.} =
    let menuItem = cast[PDMenuItemCheckmark](userdata)
    menuItem.callback(menuItem)

proc privateMenuItemOptionsCallback(userdata: pointer) {.cdecl.} =
    let menuItem = cast[PDMenuItemOptions](userdata)
    menuItem.callback(menuItem)

proc addMenuItem*(this: ptr PlaydateSys, title: string, callback: PDMenuItemButtonCallbackFunction): PDMenuItemButton =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    var menuItem = PDMenuItemButton(active: true)
    menuItem.callback = callback
    menuItem.resource = this.addMenuItem(title.cstring, privateMenuItemButtonCallback, cast[pointer](menuItem))
    menuItems.add(menuItem)
    return menuItem

proc addCheckmarkMenuItem*(this: ptr PlaydateSys, title: string, checked: bool, callback: PDMenuItemCheckmarkCallbackFunction): PDMenuItemCheckmark =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    var menuItem = PDMenuItemCheckmark(active: true)
    menuItem.callback = callback
    menuItem.resource = this.addCheckmarkMenuItem(title.cstring, if checked: 1 else: 0, privateMenuItemCheckmarkCallback, cast[pointer](menuItem))
    menuItems.add(menuItem)
    return menuItem

proc addOptionsMenuItem*(this: ptr PlaydateSys, title: string, options: seq[string], callback: PDMenuItemOptionsCallbackFunction): PDMenuItemOptions =
    privateAccess(PDMenuItem)
    privateAccess(PDMenuItemOptions)
    privateAccess(PlaydateSys)
    var menuItem = PDMenuItemOptions(active: true)
    menuItem.callback = callback
    let cOptions = options.map(proc(x: string): cstring = return x.cstring)
    menuItem.resource = this.addOptionsMenuItem(title.cstring, cast[ConstCharPtr](unsafeAddr(cOptions[0])), cOptions.len.cint,
        privateMenuItemOptionsCallback, cast[pointer](menuItem))
    menuItems.add(menuItem)
    return menuItem

proc getAllMenuItems*(this: ptr PlaydateSys): seq[PDMenuItem] =
    return menuItems

proc removeAllMenuItems*(this: ptr PlaydateSys) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    for item in menuItems:
        item.active = false
    menuItems.setLen(0)
    this.removeAllMenuItems()
# ---

proc getReduceFlashing* (this: ptr PlaydateSys): bool {.wrapApi(PlaydateSys).}
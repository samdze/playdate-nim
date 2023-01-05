{.push raises: [].}

import std/importutils
import strformat
import sequtils

import bindings/[api, types]
import bindings/system {.all.}
export system

template fmt*(arg: typed): string =
    try: &(arg) except: arg

proc logToConsole*(this: PlaydateSys, str: string) =
    privateAccess(PlaydateSys)
    this.logToConsoleRaw(str.cstring)

proc error*(this: PlaydateSys, str: string) =
    privateAccess(PlaydateSys)
    this.errorRaw(str.cstring)

proc getSecondsSinceEpoch* (this: PlaydateSys): tuple[seconds: uint, milliseconds: uint] =
    privateAccess(PlaydateSys)
    var ms: cuint
    let sec = this.getSecondsSinceEpochRaw(addr(ms)).uint
    return (seconds: sec, milliseconds: ms.uint)

# --- Update function
type PDCallbackFunction* = proc(): int {.raises: [].}
var updateCallback: PDCallbackFunction = nil

proc privateUpdate(userdata: pointer): cint {.cdecl.} =
    if updateCallback != nil:
        return updateCallback().cint
    else:
        let api = cast[PlaydateAPI](userdata)
        api.system.error("No update callback defined.")
        return 0

proc setUpdateCallback*(this: PlaydateSys, update: PDCallbackFunction, api: ptr PlaydateAPI) =
    privateAccess(PlaydateSys)
    updateCallback = update
    this.setUpdateCallbackRaw(privateUpdate, api)
# ---

proc getButtonsState* (this: PlaydateSys): tuple[current: PDButtons, pushed: PDButtons, released: PDButtons] =
    privateAccess(PlaydateSys)
    var current, pushed, released: PDButtons
    this.getButtonStateRaw(cast[ptr PDButton](addr(current)), cast[ptr PDButton](addr(pushed)), cast[ptr PDButton](addr(released)))
    return (current: current, pushed: pushed, released: released)

proc getAccelerometer* (this: PlaydateSys): tuple[x: float, y: float, z: float] =
    privateAccess(PlaydateSys)
    var x, y, z: cfloat
    this.getAccelerometerRaw(addr(x), addr(y), addr(z))
    return (x: x.float, y: y.float, z: z.float)

proc isCrankDocked* (this: PlaydateSys): bool =
    privateAccess(PlaydateSys)
    return this.isCrankDockedRaw() == 1

proc setCrankSoundsEnabled* (this: PlaydateSys, enabled: bool): bool = ##  returns previous setting
    privateAccess(PlaydateSys)
    return this.setCrankSoundsDisabledRaw(if enabled: 0 else: 1) == 0

proc getFlipped* (this: PlaydateSys): bool =
    privateAccess(PlaydateSys)
    return this.getFlippedRaw() == 1

proc setAutoLockEnabled* (this: PlaydateSys, enabled: bool) =
    privateAccess(PlaydateSys)
    this.setAutoLockDisabledRaw(if enabled: 0 else: 1)

# --- Menu items
var menuItems = newSeq[PDMenuItem]()

func isActive*(this: PDMenuItem): bool =
    privateAccess(PDMenuItem)
    return this.active

proc `title=`*(this: PDMenuItem, title: string) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    playdate.system.setMenuItemTitleRaw(this.resource, title.cstring)

proc title*(this: PDMenuItem): string =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    return $cast[cstring](playdate.system.getMenuItemTitleRaw(this.resource)) # Casting avoids compiler warnings.

proc remove*(this: PDMenuItem) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    if this.active:
        this.active = false
        playdate.system.removeMenuItemRaw(this.resource)
        for i in countdown(menuItems.len - 1, 0):
            if menuItems[i] == this:
                menuItems.del(i)
                return

# Useful when there are cicrular references between the callback and the menu item.
# But it should never happen.
# proc remove*(this: PDMenuItemButton|PDMenuItemCheckmark|PDMenuItemOptions) =
#     this.callback = nil
#     this.PDMenuItem.remove()

proc `value=`*(this: PDMenuItemCheckmark, checked: bool) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    playdate.system.setMenuItemValueRaw(this.resource, if checked: 1 else: 0)

proc value*(this: PDMenuItemCheckmark): bool =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    return playdate.system.getMenuItemValueRaw(this.resource) == 1

proc `value=`*(this: PDMenuItemOptions, index: int) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    playdate.system.setMenuItemValueRaw(this.resource, index.cint)

proc value*(this: PDMenuItemOptions): int =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    return playdate.system.getMenuItemValueRaw(this.resource).int

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

proc addMenuItem*(this: PlaydateSys, title: string, callback: PDMenuItemButtonCallbackFunction): PDMenuItemButton =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    var menuItem = PDMenuItemButton()
    menuItem.callback = callback
    menuItem.active = true
    menuItem.resource = this.addMenuItemRaw(title.cstring, privateMenuItemButtonCallback, cast[pointer](menuItem))
    menuItems.add(menuItem)
    return menuItem

proc addCheckmarkMenuItem*(this: PlaydateSys, title: string, checked: bool, callback: PDMenuItemCheckmarkCallbackFunction): PDMenuItemCheckmark =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    var menuItem = PDMenuItemCheckmark()
    menuItem.callback = callback
    menuItem.active = true
    menuItem.resource = this.addCheckmarkMenuItemRaw(title.cstring, if checked: 1 else: 0, privateMenuItemCheckmarkCallback, cast[pointer](menuItem))
    menuItems.add(menuItem)
    return menuItem

proc addOptionsMenuItem*(this: PlaydateSys, title: string, options: seq[string], callback: PDMenuItemOptionsCallbackFunction): PDMenuItemOptions =
    privateAccess(PDMenuItem)
    privateAccess(PDMenuItemOptions)
    privateAccess(PlaydateSys)
    var menuItem = PDMenuItemOptions()
    menuItem.callback = callback
    menuItem.active = true
    let cOptions = options.map(proc(x: string): cstring = return x.cstring)
    menuItem.resource = this.addOptionsMenuItemRaw(title.cstring, cast[ConstCharPtr](unsafeAddr(cOptions[0])), cOptions.len.cint,
        privateMenuItemOptionsCallback, cast[pointer](menuItem))
    menuItems.add(menuItem)
    return menuItem

proc getAllMenuItems*(this: PlaydateSys): seq[PDMenuItem] =
    return menuItems

proc removeAllMenuItems*(this: PlaydateSys) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    for item in menuItems:
        item.active = false
    menuItems.setLen(0)
    this.removeAllMenuItemsRaw()
# ---

proc getReduceFlashing* (this: PlaydateSys): bool =
    privateAccess(PlaydateSys)
    return this.getReduceFlashingRaw() == 1
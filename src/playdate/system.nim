{.push raises: [].}

import std/importutils
import strformat
import sequtils

import bindings/[api, types]
import bindings/system
import lcdbitmap {.all.}

# Only export public symbols, then import all
export system
{.hint[DuplicateModuleImport]: off.}
import bindings/system {.all.}

template fmt*(arg: typed): string =
    try: &(arg) except: arg

proc logToConsole*(this: ptr PlaydateSys, str: string) =
    privateAccess(PlaydateSys)
    this.logToConsole(str.cstring)

proc error*(this: ptr PlaydateSys, str: string) =
    privateAccess(PlaydateSys)
    this.error(str.cstring)

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

proc getButtonState* (this: ptr PlaydateSys): tuple[current: PDButtons, pushed: PDButtons, released: PDButtons] =
    privateAccess(PlaydateSys)
    var current, pushed, released: uint32
    this.getButtonState(cast[ptr PDButton](addr(current)), cast[ptr PDButton](addr(pushed)), cast[ptr PDButton](addr(released)))
    return (current: cast[PDButtons](current), pushed: cast[PDButtons](pushed), released: cast[PDButtons](released))

proc getAccelerometer* (this: ptr PlaydateSys): tuple[x: float32, y: float32, z: float32] =
    privateAccess(PlaydateSys)
    var x, y, z: cfloat
    this.getAccelerometer(addr(x), addr(y), addr(z))
    return (x: x.float32, y: y.float32, z: z.float32)

proc isCrankDocked* (this: ptr PlaydateSys): bool =
    privateAccess(PlaydateSys)
    return this.isCrankDocked() == 1

proc setCrankSoundsEnabled* (this: ptr PlaydateSys, enabled: bool): bool = ##  returns previous setting
    privateAccess(PlaydateSys)
    return this.setCrankSoundsDisabled(if enabled: 0 else: 1) == 0

proc getFlipped* (this: ptr PlaydateSys): bool =
    privateAccess(PlaydateSys)
    return this.getFlipped() == 1

proc setAutoLockEnabled* (this: ptr PlaydateSys, enabled: bool) =
    privateAccess(PlaydateSys)
    this.setAutoLockDisabled(if enabled: 0 else: 1)

# --- Menu items
privateAccess(PDMenuItem)
var menuItems = newSeq[PDMenuItem](0)

func isActive*(this: PDMenuItem): bool =
    privateAccess(PDMenuItem)
    return this.active

proc `title=`*(this: PDMenuItem, title: string) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    playdate.system.setMenuItemTitle(this.resource, title.cstring)

proc title*(this: PDMenuItem): string =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    return $playdate.system.getMenuItemTitle(this.resource)

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

proc `value=`*(this: PDMenuItemCheckmark, checked: bool) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    playdate.system.setMenuItemValue(this.resource, if checked: 1 else: 0)

proc value*(this: PDMenuItemCheckmark): bool =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    return playdate.system.getMenuItemValue(this.resource) == 1

proc `value=`*(this: PDMenuItemOptions, index: int) =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    playdate.system.setMenuItemValue(this.resource, index.cint)

proc value*(this: PDMenuItemOptions): int =
    privateAccess(PDMenuItem)
    privateAccess(PlaydateSys)
    return playdate.system.getMenuItemValue(this.resource).int

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

proc setMenuImage*(this: ptr PlaydateSys, image: LCDBitmap, xOffset: int32 = 0) =
    privateAccess(PlaydateSys)
    this.setMenuImage(
        # if image != nil: image.resource else: nil
        image.resource,
        xOffset.cint
    )

proc getReduceFlashing* (this: ptr PlaydateSys): bool =
    privateAccess(PlaydateSys)
    return this.getReduceFlashing() == 1


import std/random

proc randomize*(this: ptr PlaydateSys) =
    randomize(this.getSecondsSinceEpoch().milliseconds.int64)
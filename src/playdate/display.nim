{.push raises: [].}

import std/importutils

import bindings/display

# Only export public symbols, then import all
export display
{.hint[DuplicateModuleImport]: off.}
import bindings/display {.all.}

var 
    refreshRate = 30f
        ## bookkeeping variable for refresh rate, because API does not provide a getter.
        ## Initial value is the rate that is set on device boot

proc setInverted* (this: ptr PlaydateDisplay, inverted: bool) =
    privateAccess(PlaydateDisplay)
    this.setInverted(if inverted: 1 else: 0)

proc setFlipped* (this: ptr PlaydateDisplay, x: bool, y: bool) =
    privateAccess(PlaydateDisplay)
    this.setFlipped(if x: 1 else: 0, if y: 1 else: 0)


proc getRefreshRate* (this: ptr PlaydateDisplay): float32 =
    refreshRate

proc setRefreshRate* (this: ptr PlaydateDisplay, rate: float32) =
    privateAccess(PlaydateDisplay)
    refreshRate = rate
    this.setRefreshRate(rate)
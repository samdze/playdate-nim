{.push raises: [].}

import std/importutils

import bindings/display

# Only export public symbols, then import all
export display
{.hint[DuplicateModuleImport]: off.}
import bindings/display {.all.}

proc setInverted* (this: ptr PlaydateDisplay, inverted: bool) =
    privateAccess(PlaydateDisplay)
    this.setInverted(if inverted: 1 else: 0)

proc setFlipped* (this: ptr PlaydateDisplay, x: bool, y: bool) =
    privateAccess(PlaydateDisplay)
    this.setFlipped(if x: 1 else: 0, if y: 1 else: 0)
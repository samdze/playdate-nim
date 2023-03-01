{.push raises: [].}

import std/importutils

import bindings/[display, utils]

# Only export public symbols, then import all
export display
{.hint[DuplicateModuleImport]: off.}
import bindings/display {.all.}

proc setInverted* (this: ptr PlaydateDisplay, inverted: bool) {.wrapApi(PlaydateDisplay).}

proc setFlipped* (this: ptr PlaydateDisplay, x: bool, y: bool) {.wrapApi(PlaydateDisplay).}
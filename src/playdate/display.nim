{.push raises: [].}

import std/importutils

import bindings/display {.all.}
export display

proc setInverted* (this: PlaydateDisplay, inverted: bool) =
    privateAccess(PlaydateDisplay)
    this.setInvertedRaw(if inverted: 1 else: 0)

proc setFlipped* (this: PlaydateDisplay, x: bool, y: bool) =
    privateAccess(PlaydateDisplay)
    this.setFlippedRaw(if x: 1 else: 0, if y: 1 else: 0)
# Package

version       = "0.1.0"
author        = "samdze"
description   = "An example package using the Playdate nim bindings"
license       = "MIT"
srcDir        = "src"
bin           = @["playdate_example"]


# Dependencies

requires "nim >= 1.6.10"
requires "playdate"
include playdate/build/nimble

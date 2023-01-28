# Package

version       = "0.7.0"
author        = "Samuele Zolfanelli"
description   = "An example application using the Playdate Nim bindings"
license       = "MIT"
srcDir        = "src"
bin           = @["playdate_example"]


# Dependencies

requires "nim >= 1.6.10"
requires "playdate"
include playdate/build/nimble

# Package

version       = "0.8.0"
author        = "Samuele Zolfanelli"
description   = "Unit tests for the Playdate Nim bindings"
license       = "MIT"
srcDir        = "src"
bin           = @["playdate_tests"]


# Dependencies

requires "nim >= 1.6.10"
requires "playdate"
include playdate/build/nimble

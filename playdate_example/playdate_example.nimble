# Package

version       = "0.8.0"
author        = "Samuele Zolfanelli"
description   = "An example application using the Playdate Nim bindings"
license       = "MIT"
## The main entrypoint of your game. In this example the file `playdate_example/src/playdate_example.nim` is
## the first nim file that is executed when the game is started
## note that the value of bin must match the project folder name
srcDir        = "src"
bin           = @["playdate_example"]


# Dependencies

requires "nim >= 1.6.10"
requires "playdate"
include playdate/build/nimble

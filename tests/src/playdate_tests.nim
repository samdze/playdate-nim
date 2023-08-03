##
## This file is the primary entry point for running the tests inside the simulator.
## It requires that we spin up the full Lua runtime, as that allows us to then
## exit from the simulator.
##

import playdate/api
import ../t_buttons
import ../t_graphics

proc runTests() {.raises: [].} =
    try:
        execButtonsTests()
        execGraphicsTests(true)
    except Exception as e:
        quit(e.msg & "\n" & e.getStackTrace)

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInitLua:
        runTests()

initSDK()

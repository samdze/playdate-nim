##
## This file is the primary entry point for running the tests inside the simulator.
## It requires that we spin up the full Lua runtime, as that allows us to then
## exit from the simulator.
##

import playdate/api
import ../[ t_system, t_buttons, t_graphics, t_nineslice, t_files, t_midi, t_scoreboards]

proc runTests() {.raises: [].} =
    try:
        execSystemTests(false)
        execButtonsTests()
        execGraphicsTests(true)
        execNineSliceTests(true)
        execFilesTest()
        execMidiTests(true)
        execScoreboardTests()
    except Exception as e:
        quit(e.msg & "\n" & e.getStackTrace)

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInitLua:
        runTests()

initSDK()

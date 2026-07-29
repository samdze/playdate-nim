##
## This file is the primary entry point for running the tests inside the simulator.
##

import playdate/api, std/unittest
import ../[t_system, t_buttons, t_graphics, t_nineslice, t_files, t_midi, t_scoreboards]

# Force the tests to fail with an error code on a test failure
abortOnError = true

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

  # We have to manually quit, otherwise the simulator will continue running
  quit(0)

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInitLua:
    runTests()

initSDK()

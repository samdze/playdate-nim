import unittest, playdate/api

proc execSystemTests*(runnable: bool)=
  suite "System API":

    test "setMenuImage with nil":
      if(runnable):
          playdate.system.setMenuImage(nil, 0)

    test "setMenuImage with bitmap":
      if(runnable):
        let bgBitmap = playdate.graphics.newBitmap(400, 240, kColorBlack)
        playdate.system.setMenuImage(bgBitmap, 0)

when isMainModule:
    # We can't run these methods from the tests, so we're only interested in
    # whether they compile.
    execSystemTests(runnable = false)
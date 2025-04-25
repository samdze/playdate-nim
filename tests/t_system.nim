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

    test "runCatching typed int with exception":
      if(runnable):
        var result: int
        result = runCatching(proc(): int = raise newException(ValueError, "test Exveption with int return type"))
        assert(result == 0)

    test "runCatching untyped with exception":
      if runnable:
        runCatching(proc(): void = raise newException(ValueError, "test exception with void return type"))

    # for the test cases below no logging to playdate console is needed, so they can be run on on any environment

    test "runCatching typed int without exception":
      var result: int
      result = runCatching(proc(): int = 1)
      assert(result == 1)

    test "runCatching typed string without exception":
      var result: string
      result = runCatching(proc(): string = "test")
      assert(result == "test")

    test "runCatching typed bool without exception":
      var result: bool
      result = runCatching(proc(): bool = true)
      assert(result == true)

    test "runCatching untyped without exception":
      runCatching(proc(): void = discard)

when isMainModule:
    # We can't run these methods from the tests, so we're only interested in
    # whether they compile.
    execSystemTests(runnable = false)
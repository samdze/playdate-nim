import unittest, playdate/api, strutils


proc execGraphicsTests*(runnable: bool) =

    suite "Graphics API":

        template bitviewTests(create: untyped) =
            if runnable:
                var value = create
                discard value.get(1, 1)
                # Using graphics.set to disambiguate.
                # Otherwise, Nim complains in cases like this when we are inside a template.
                graphics.set(value, 0, 0)
                value.clear(0, 0)
                graphics.set(value, 0, 0, kColorWhite)
                graphics.set(value, 0, 0, kColorBlack)

        test "Setting Frame bits should compile":
            bitviewTests(playdate.graphics.getFrame())

        test "Setting DisplayFrame bits should compile":
            bitviewTests(playdate.graphics.getDisplayFrame())

        test "Setting Bitmap bits should compile":
            bitviewTests(playdate.graphics.newBitmap(10, 10, kColorWhite).getData)

        template colorTests(colorOrPattern: untyped) =
            if runnable:
                let img = playdate.graphics.newBitmap(10, 10, colorOrPattern)
                img.clear(colorOrPattern)

                playdate.graphics.clear(colorOrPattern)
                playdate.graphics.drawLine(0, 0, 10, 10, 2, colorOrPattern)
                playdate.graphics.fillTriangle(0, 0, 10, 10, 0, 10, colorOrPattern)
                playdate.graphics.drawRect(0, 0, 10, 10, colorOrPattern)
                playdate.graphics.fillRect(0, 0, 10, 10, colorOrPattern)
                playdate.graphics.drawEllipse(0, 0, 10, 10, 2, 0.0, 90.0, colorOrPattern)
                playdate.graphics.fillEllipse(0, 0, 10, 10, 2, 0.0, colorOrPattern)
                playdate.graphics.fillPolygon(@[0, 0, 10, 10, 0, 10], colorOrPattern, kPolygonFillEvenOdd)

        test "Color methods could compile given a solid color":
            colorTests(kColorWhite)

        test "Color methods could compile given a pattern":
            let pattern = makeLCDPattern(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
            colorTests(pattern)

        test "Pattern creation should compile":
            if runnable:
                let img = playdate.graphics.newBitmap(10, 10, kColorWhite)
                discard playdate.graphics.createPattern(img, 0, 0)

        test "DebugBitmap should not be freed after use":
            if runnable:
                discard playdate.graphics.getDebugBitmap()
                # if the bitmap was freed, this would crash
                discard playdate.graphics.getDebugBitmap()

        test "Bitmaps should be loadable from files":
            if runnable:
                let img = playdate.graphics.newBitmap("boxes.png")

                let expect = join(@[
                    "          ",
                    "  ███░░░  ",
                    "  █░░██░  ",
                    "  █░░██░  ",
                    "  █░░██░  ",
                    "  █░░██░  ",
                    "  █░░██░  ",
                    "  █░░██░  ",
                    "  ███░░░  ",
                    "          \n",
                ], "\n")

                check($(img) == expect)

        test "Creating bitmaps programaticlly":
            if runnable:
                var img = playdate.graphics.newBitmap(2, 2, kColorWhite)
                img.set(0, 0, kColorWhite)
                img.set(1, 0, kColorBlack)
                check($img == "░█\n░░\n")

        test "Creating bitmaps programaticlly with clear pixels":
            if runnable:
                var img = playdate.graphics.newBitmap(2, 2, kColorWhite)
                discard img.setBitmapMask()
                img.set(0, 0, kColorWhite)
                img.set(1, 0, kColorBlack)
                img.set(0, 1, kColorClear)
                check($img == "░█\n ░\n")

when isMainModule:
    # We can't run these methods from the tests, so we're only interested in
    # whether they compile.
    execGraphicsTests(runnable = false)

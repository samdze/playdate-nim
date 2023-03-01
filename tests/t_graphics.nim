import unittest, playdate/api

suite "Graphics API":

    template colorTests(value: untyped) =
        # We can't run these methods from the tests, so we're only interested in
        # whether they compile
        if false:
            let img = playdate.graphics.newBitmap(10, 10, value)
            img.clear(value)

            playdate.graphics.clear(value)
            playdate.graphics.drawLine(0, 0, 10, 10, 2, value)
            playdate.graphics.fillTriangle(0, 0, 10, 10, 0, 10, value)
            playdate.graphics.drawRect(0, 0, 10, 10, value)
            playdate.graphics.fillRect(0, 0, 10, 10, value)
            playdate.graphics.drawEllipse(0, 0, 10, 10, 2, 0.0, 90.0, value)
            playdate.graphics.fillEllipse(0, 0, 10, 10, 2, 0.0, value)
            playdate.graphics.fillPolygon(@[0, 0, 10, 10, 0, 10], value, kPolygonFillEvenOdd)

    test "Color methods could compile given a solid color":
        colorTests(kColorWhite)

    test "Color methods could compile given a pattern":
        let pattern = makeLCDPattern(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
        colorTests(pattern)

    test "Pattern creation should compile":
        if false:
            let img = playdate.graphics.newBitmap(10, 10, kColorWhite)
            discard playdate.graphics.createPattern(img, 0, 0)
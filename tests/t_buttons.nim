import unittest, playdate/api

suite "Button press detection":

    let buttons = [
        kButtonLeft:  0b0000_0001,
        kButtonRight: 0b0000_0010,
        kButtonUp:    0b0000_0100,
        kButtonDown:  0b0000_1000,
        kButtonB:     0b0001_0000,
        kButtonA:     0b0010_0000,
    ]

    for testButton, bitfield in buttons:
        test "Detecting " & $testButton:
            let buttons = cast[PDButtons](bitfield)
            for button in low(PDButton)..high(PDButton):
                if button == testButton:
                    check(button in buttons)
                else:
                    check(button notin buttons)
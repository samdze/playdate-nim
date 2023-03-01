import playdate/api

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"
const NIM_IMAGE_PATH = "/images/nim_logo"
const PLAYDATE_NIM_IMAGE_PATH = "/images/playdate_nim"

var font: LCDFont

var playdateNimBitmap: LCDBitmap
var nimLogoBitmap: LCDBitmap

var sprite: LCDSprite

var samplePlayer: SamplePlayer
var filePlayer: FilePlayer

var x = int(LCD_COLUMNS / 2)
var y = int(LCD_ROWS / 2) + 32

proc update(): int =
    # playdate is the global PlaydateAPI instance, available when playdate/api is imported
    let buttonsState = playdate.system.getButtonsState()

    if kButtonRight in buttonsState.current:
        x += 10
    if kButtonLeft in buttonsState.current:
        x -= 10
    if kButtonUp in buttonsState.current:
        y -= 10
    if kButtonDown in buttonsState.current:
        y += 10

    if kButtonA in buttonsState.pushed:
        samplePlayer.play(1, 1.0)

    let goalX = x.toFloat
    let goalY = y.toFloat
    let res = sprite.moveWithCollisions(goalX, goalY)
    x = res.actualX.int
    y = res.actualY.int
    if res.collisions.len > 0:
        # fmt allows the "{variable}" syntax for formatting strings
        playdate.system.logToConsole(fmt"{res.collisions.len} collision(s) occurred!")

    playdate.sprite.drawSprites()
    playdate.system.drawFPS(0, 0)

    playdate.graphics.setDrawMode(kDrawModeNXOR)
    playdate.graphics.drawText("Playdate Nim!", 1, 12)

    playdate.graphics.setDrawMode(kDrawModeCopy)
    playdateNimBitmap.draw(22, 65, kBitmapUnflipped)

    return 1

import std/json
type
    Equip = ref object
        name: string
        damage: int
    Entity = ref object
        name: string
        enemy: bool
        health: int
        equip: seq[Equip]

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInit:
        playdate.display.setRefreshRate(50)
        # Enables the accelerometer even if it's not used here
        playdate.system.setPeripheralsEnabled(kAllPeripherals)

        # Errors are handled through exceptions
        try:
            samplePlayer = playdate.sound.newSamplePlayer("/audio/jingle")
        except:
            playdate.system.logToConsole(getCurrentExceptionMsg())
        # Inline try/except
        filePlayer = try: playdate.sound.newFilePlayer("/audio/finally_see_the_light") except: nil

        filePlayer.play(0)

        # Add a checkmark menu item that plays a sound when switched and unpaused
        discard playdate.system.addCheckmarkMenuItem("Checkmark", false,
            proc(menuItem: PDMenuItemCheckmark) =
                samplePlayer.play(1, 1.0)
        )

        font = try: playdate.graphics.newFont(FONT_PATH) except: nil
        playdate.graphics.setFont(font)

        playdateNimBitmap = try: playdate.graphics.newBitmap(PLAYDATE_NIM_IMAGE_PATH) except: nil
        nimLogoBitmap = try: playdate.graphics.newBitmap(NIM_IMAGE_PATH) except: nil

        sprite = playdate.sprite.newSprite()
        sprite.add()
        sprite.moveTo(x.float, y.float)
        sprite.setImage(nimLogoBitmap, kBitmapUnflipped)
        sprite.collideRect = PDRect(x: 0, y: 12, width: 64, height: 40)
        # Slide when a collision occurs
        sprite.setCollisionResponseFunction(
            proc(sprite, other: LCDSprite): auto =
                kCollisionTypeSlide
        )

        # Create screen walls
        let sprite1 = playdate.sprite.newSprite()
        sprite1.add()
        sprite1.moveTo(0, -1)
        sprite1.collideRect = PDRect(x: 0, y: 0, width: 400, height: 1)
        sprite1.collisionsEnabled = true

        let sprite2 = playdate.sprite.newSprite()
        sprite2.add()
        sprite2.moveTo(400, 0)
        sprite2.collideRect = PDRect(x: 0, y: 0, width: 1, height: 240)

        let sprite3 = playdate.sprite.newSprite()
        sprite3.add()
        sprite3.moveTo(-1, 0)
        sprite3.collideRect = PDRect(x: 0, y: 0, width: 1, height: 240)

        let sprite4 = playdate.sprite.newSprite()
        sprite4.add()
        sprite4.moveTo(0, 240)
        sprite4.collideRect = PDRect(x: 0, y: 0, width: 400, height: 1)

        try:
            # Decode a JSON string to an object, type safe!
            let jsonString = playdate.file.open("/json/data.json", kFileRead).readString()
            let obj = parseJson(jsonString).to(Entity)
            playdate.system.logToConsole(fmt"JSON decoded: {obj.repr}")
            # Encode an object to a JSON string, %* is the encode operator
            playdate.system.logToConsole(fmt"JSON encoded: {(%* obj).pretty}")

            let faultyString = playdate.file.open("/json/error.json", kFileRead).readString()
            # This generates an exception
            discard parseJson(faultyString).to(Entity)
        except:
            playdate.system.logToConsole("This below is an expected error:")
            playdate.system.logToConsole(getCurrentExceptionMsg())

        # Set the update callback
        playdate.system.setUpdateCallback(update)

# Used to setup the SDK entrypoint
initSDK()
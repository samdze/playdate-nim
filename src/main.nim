include playdate/init

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"
const IMAGE_PATH = "/images/playdate_icon_large"
const BALL_IMAGE_PATH = "/images/ball"
const TEXT_WIDTH = 86
const TEXT_HEIGHT = 16

var font: LCDFont = nil
var x = int((400 - TEXT_WIDTH) / 2)
var y = int((240 - TEXT_HEIGHT) / 2)
var dx = 1
var dy = 2
var globalBitmap: LCDBitmap = nil
var ballBitmap: LCDBitmap = nil
var sprite: LCDSprite
var imageTable: LCDBitmapTable
# var audioFile: FilePlayerPtr
# var soundFile: SamplePlayerPtr

var samplePlayer: SamplePlayer
var filePlayer: FilePlayer

# type Point = object
#     x: int32
#     y: int32

# var points: seq[Point] = @[
#     Point(x: 30, y: 30),
#     Point(x: 320, y: 90),
#     Point(x: 120, y: 180)
# ]

proc update(): int =
    var bitmap: LCDBitmap
    try:
        bitmap = playdate.graphics.loadBitmap(IMAGE_PATH)
    except:
        playdate.system.error(fmt"{compilerInfo()} {getCurrentExceptionMsg()}")

    # let sprite2 = api.sprite.newSprite()
    # api.sprite.addSprite(sprite2)
    # api.sprite.setImage(sprite2, globalBitmap, kBitmapUnflipped)
    # # api.sprite.setCollideRect(sprite2, PDRect(x: 0, y: 0, width: 50, height: 50))
    # api.sprite.setCollisionsEnabled(sprite2, false)
    # api.sprite.moveBy(sprite2, 100, 100)
    # api.sprite.setVisible(sprite2, false)
        

    playdate.graphics.clear(kColorWhite.LCDColor)
    
    playdate.graphics.setFont(font)

    # x += dx
    # y += dy

    playdate.graphics.drawText("Hello World!", len("Hello World!"), kASCIIEncoding, x, y)
    # api.graphics.drawBitmap(bitmap, x, y + 14, kBitmapUnflipped)

    playdate.sprite.drawSprites()

    # points[2].y = 100 + (sin(x.toFloat / 10.0) * 10.0).int32

    # api.graphics.fillPolygon(points, kColorBlack.LCDColor, kPolygonFillEvenOdd)

    let buttonsState = playdate.system.getButtonsState()
    
    if buttonsState.current.check(kButtonRight):
        x += 20
        # dx += 1
    if buttonsState.current.check(kButtonLeft):
        x -= 20
        # dx -= 1
    if buttonsState.current.check(kButtonUp):
        # discard api.sound.sampleplayer.play(soundFile, 1, 1.0)
        samplePlayer.play(1, 1.0)
        y -= 20
        # dy -= 1
    if buttonsState.current.check(kButtonDown):
        y += 20

    if x < 0 or x > LCD_COLUMNS - TEXT_WIDTH:
        dx = -dx
    
    if y < 0 or y > LCD_ROWS - TEXT_HEIGHT:
        dy = -dy
    
    let goalX = x.toFloat
    let goalY = y.toFloat
    let res = playdate.sprite.moveWithCollisions(sprite, goalX, goalY)
    x = (res.actualX + 24).int
    y = (res.actualY + 24).int
    # api.system.logToConsole(fmt"goal: ({goalX}, {goalY}), result: ({x}, {y}), actual: ({res.actualX}, {res.actualY})")
    if res.collisions.len > 0:
        # api.system.logToConsole(fmt"Collisions are {res.collisions.len}!")
        if res.collisions.len > 1:
            playdate.system.logToConsole(fmt"A multiple collision of {res.collisions.len}!")
        for col in res.collisions:
            playdate.system.logToConsole(fmt"{col.move}")

    playdate.system.drawFPS(0, 0)
    # api.sprite.removeSprite(sprite)
    # api.sprite.removeSprite(sprite2)
    # api.sprite.removeSprites(@[sprite2])
    # api.sprite.removeAllSprites()
    # var imageTable = try: api.graphics.loadBitmapTable("/images/ball_sheet") except: nil
    # ballBitmap = api.graphics.getTableBitmap(imageTable, 1)

    return 1

import sugar

proc handler(event: PDSystemEvent, keycode: uint) =
    if event == kEventInit:
        playdate.display.setRefreshRate(50)
        playdate.system.setPeripheralsEnabled(kAllPeripherals)

        samplePlayer = playdate.sound.newSamplePlayer("/audio/bullet_shot_01")

        filePlayer = playdate.sound.newFilePlayer("/audio/nausicaa_theme")

        # let filePlayer2 = newFilePlayer("/audio/nausicaa_theme")

        filePlayer.play(0)

        discard playdate.sound.getCurrentTime()

        # samplePlayer = SamplePlayer()

        # audioFile = api.sound.fileplayer.newPlayer()
        # try: discard api.sound.fileplayer.loadIntoPlayer(audioFile, "/audio/nausicaa_theme") except: discard
        # discard api.sound.fileplayer.play(audioFile, 0)
        # # api.sound.fileplayer.freePlayer(audioFile)

        # soundFile = api.sound.sampleplayer.newPlayer()
        # let audioSample = api.sound.sample.load("/audio/bullet_shot_01")
        # try: api.sound.sampleplayer.setSample(soundFile, audioSample) except: discard

        font = try: playdate.graphics.loadFont(FONT_PATH) except: nil
        # sprite = api.sprite.newSprite()
        # api.sprite.addSprite(sprite)

        var imageTable = try: playdate.graphics.loadBitmapTable("/images/ball_sheet") except: nil
        ballBitmap = playdate.graphics.getTableBitmap(imageTable, 1)

        globalBitmap = try: playdate.graphics.loadBitmap(IMAGE_PATH) except: nil
        ballBitmap = try: playdate.graphics.loadBitmap(BALL_IMAGE_PATH) except: nil

        

        sprite = playdate.sprite.newSprite()
        playdate.sprite.addSprite(sprite)
        playdate.sprite.setImage(sprite, ballBitmap, kBitmapUnflipped)
        playdate.sprite.setCollideRect(sprite, PDRect(x: 0, y: 0, width: 48, height: 48))
        playdate.sprite.moveTo(sprite, x.float, y.float)
        let spriteAddr = addr(sprite[])
        # playdate.system.logToConsole(fmt"sprite has address {spriteAddr.repr}")

        playdate.sprite.setCollisionResponseFunction(sprite,
            (self, other) => kCollisionTypeSlide
        )
        # playdate.system.logToConsole(fmt"again {spriteAddr.repr}")
        # playdate.sprite.setBounds(sprite, PDRect(x: 0, y: 0, width: 32, height: 32))

        let sprite1 = playdate.sprite.newSprite()
        playdate.sprite.addSprite(sprite1)
        # playdate.sprite.setImage(sprite1, globalBitmap, kBitmapUnflipped)
        playdate.sprite.setCollideRect(sprite1, PDRect(x: 0, y: 0, width: 400, height: 1))
        playdate.sprite.setCollisionsEnabled(sprite1, true)
        playdate.sprite.moveTo(sprite1, 0, -1)

        let sprite2 = playdate.sprite.newSprite()
        playdate.sprite.addSprite(sprite2)
        # playdate.sprite.setImage(sprite2, globalBitmap, kBitmapUnflipped)
        playdate.sprite.setCollideRect(sprite2, PDRect(x: 0, y: 0, width: 1, height: 240))
        playdate.sprite.moveTo(sprite2, 400, 0)

        let sprite3 = playdate.sprite.newSprite()
        playdate.sprite.addSprite(sprite3)
        # playdate.sprite.setImage(sprite2, globalBitmap, kBitmapUnflipped)
        playdate.sprite.setCollideRect(sprite3, PDRect(x: 0, y: 0, width: 1, height: 240))
        playdate.sprite.moveTo(sprite3, -1, 0)

        let sprite4 = playdate.sprite.newSprite()
        playdate.sprite.addSprite(sprite4)
        # playdate.sprite.setImage(sprite2, globalBitmap, kBitmapUnflipped)
        playdate.sprite.setCollideRect(sprite4, PDRect(x: 0, y: 0, width: 400, height: 1))
        playdate.sprite.moveTo(sprite4, 0, 240)

        playdate.system.setUpdateCallback(update, playdate)

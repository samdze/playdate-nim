{.push raises: [].}

import ../bindings/graphics

proc drawText*(this: PlaydateGraphics, text: string, len: uint, encoding: PDStringEncoding, x: int, y: int): int {.discardable.}

proc loadFont*(this: PlaydateGraphics, path: string): LCDFont {.raises: [IOError]}

proc loadBitmap*(this: PlaydateGraphics, path: string): LCDBitmap {.raises: [IOError]}
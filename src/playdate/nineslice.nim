import graphics
import domain/lcdbitmap
import std/[importutils, bitops, math, strutils]

privateAccess(BitmapData)
privateAccess(LCDBitmap)

type
    NineSliceRow {.byref.} = object
        ## The bytes for a single row within a nine slice
        leftBytes: seq[uint8]
        middleBytes: seq[uint8]
        rightBytes: seq[uint8]
        leftRightBitLen: int

    NineSliceData = ref object
        ## Stores the rows for a single nine slice bitmap
        top: seq[NineSliceRow]
        middle: seq[NineSliceRow]
        bottom: seq[NineSliceRow]

    NineSlice* = ref object
        ## A precalculated nine slice
        image: NineSliceData
        mask: NineSliceData

func copyBits(
    source: ptr UncheckedArray[uint8];
    target: var seq[uint8];
    sourceStartBit, sourceOffsetBit, sourceLen, targetStartBit, targetLen: int
) =
    ## Copies a sequence of bits from the source to the target, where all bit positions are absolute relative to
    ## the start of the source or target
    let minLength = ceil((targetStartBit + targetLen) / 8).toInt
    target.setLen(max(target.len, minLength))

    for bit in 0..<targetLen:
        let sourceBit = sourceStartBit + ((bit + sourceOffsetBit) mod sourceLen)
        let targetBit = targetStartBit + bit

        if source[sourceBit div 8].testBit(7 - sourceBit mod 8):
            target[targetBit div 8].setBit(7 - targetBit mod 8)

func fillNineSliceRow(row: var NineSliceRow; source: BitmapData; y, leftRightBitLen: int) =
    ## Each row gets a precalculated set of data that makes it faster to apply
    let sourceStartBit = source.rowbytes * y * 8
    let midSectionWidth = source.width - (2 * leftRightBitLen)

    # Copy the bits for the leftmost column of the row
    copyBits(source.data, row.leftBytes, sourceStartBit, 0, leftRightBitLen, 0, leftRightBitLen)

    # If the leftmost bytes don't fill in to an even 8 bits, we pad it with bits from the center stretchable section.
    # When drawing, this allows us to just blindly draw the first byte without any bit twiddling
    copyBits(
        source.data,
        row.leftBytes,
        sourceStartBit =    sourceStartBit + leftRightBitLen,
        sourceOffsetBit =   0,
        sourceLen =         midSectionWidth,
        targetStartBit =    leftRightBitLen,
        targetLen =         8 - (leftRightBitLen mod 8),
    )

    # Fills in the bytes for the middle section. We fill until the pattern repeats to reduce the amount of bit
    # twiddling that needs to be done during render
    copyBits(
        source.data,
        row.middleBytes,
        sourceStartBit =    sourceStartBit + leftRightBitLen,
        # Because the left bytes are filled in with some of the middle section bytes, we need to start copying
        # bits at an offset that reflect the values that were already written. The following parameter is a calculation
        # of what bit we left off on
        sourceOffsetBit =   (8 - (leftRightBitLen mod 8)) mod midSectionWidth,
        sourceLen =         midSectionWidth,
        targetStartBit =    0,
        targetLen =         midSectionWidth * 8,
    )

    # Fill the bytes for the right side of the nine slice
    copyBits(source.data, row.rightBytes, sourceStartBit + source.width - leftRightBitLen, 0, leftRightBitLen, 0, leftRightBitLen)
    row.leftRightBitLen = leftRightBitLen

func createNineSliceData(source: BitmapData): NineSliceData =
    ## Precalculates rendering instructions for a single bitmap
    let leftRightBitLen = source.width div 3
    let sliceHeight = source.height div 3

    result = NineSliceData(
        top: newSeq[NineSliceRow](sliceHeight),
        middle: newSeq[NineSliceRow](source.height - sliceHeight * 2),
        bottom: newSeq[NineSliceRow](sliceHeight),
    )

    # Precalculate the rows for the top and bottom sections
    for i in 0..<sliceHeight:
        result.top[i].fillNineSliceRow(source, i, leftRightBitLen)
        result.bottom[i].fillNineSliceRow(source, source.height - sliceHeight + i, leftRightBitLen)

    # Precalculate the rows for the stretchy middle section
    for i in 0..<(source.height - sliceHeight * 2):
        result.middle[i].fillNineSliceRow(source, sliceHeight + i, leftRightBitLen)

proc newNineSlice*(source: LCDBitmap): NineSlice =
    ## Precalculates a drawable nine slice from an image: https://en.wikipedia.org/wiki/9-slice_scaling
    assert(source.width >= 3)
    assert(source.height >= 3)
    return NineSlice(
        image: createNineSliceData(source.getData),
        mask: if source.getBitmapMask.resource == nil: nil else: createNineSliceData(source.getBitmapMask.getData)
    )

func overlapBytes(left, right: uint8, offset: int): uint8 =
    ## Given two bytes, creates a new byte that is partially made up of the left byte, and partially made up of
    ## the right hand byte. The amount taken from each is determined by the `offset`
    let leftContribution = left shl (8 - offset)
    let rightContribution = right shr offset
    result = leftContribution or rightContribution

func drawRow(target: var BitmapData, source: NineSliceRow, targetY: int) =
    ## Draws a single row to a nine slice.
    let targetOffsetByte = target.rowbytes * targetY

    # Draw the left column, a byte at a time
    for i, byteValue in source.leftBytes:
        target.data[i + targetOffsetByte] = byteValue

    # Draw the stretched out middle column
    let imageWidthInBytes = target.width div 8
    let middleBytesLen = imageWidthInBytes - (2 * (source.leftRightBitLen div 8))
    for i in 0..<middleBytesLen:
        target.data[i + targetOffsetByte + source.leftBytes.len] = source.middleBytes[i mod source.middleBytes.len]

    # Draw the right column, but we need to do some twiddling to align it properly. The position of the right column
    # isn't something we can align ahead of time, so once we draw the left and middle portions, we need to overlay the
    # right column and adjust its alignment
    let rightColStartByte = (target.width - source.leftRightBitLen) div 8
    let overlapBits = (target.width - source.leftRightBitLen) mod 8
    var existingByte = target.data[targetOffsetByte + rightColStartByte] shr (8 - overlapBits)
    for i in 0..(imageWidthInBytes - rightColStartByte):
        let rightByte = source.rightBytes[min(i, source.rightBytes.len - 1)]
        target.data[targetOffsetByte + rightColStartByte + i] = overlapBytes(existingByte, rightByte, overlapBits)
        existingByte = rightByte

func drawData(target: var BitmapData; source: NineSliceData) =
    ## Draws a nine slice to a single bitmap target
    for i in 0..<source.top.len:
        target.drawRow(source.top[i], i)

    for i in 0..<(target.height - source.top.len - source.bottom.len):
        target.drawRow(source.middle[i mod source.middle.len], source.top.len + i)

    for i in 0..<source.bottom.len:
        target.drawRow(source.bottom[i], target.height - source.bottom.len + i)

proc draw*(target: var LCDBitmap; source: NineSlice) =
    ## Draws a nine slice to an image
    var data = target.getData
    drawData(data, source.image)
    if source.mask != nil and target.getBitmapMask.resource != nil:
        var maskData = target.getBitmapMask.getData
        drawData(maskData, source.mask)
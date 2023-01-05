{.push raises: [].}

import utils

sdktype PlaydateDisplay:
    type PlaydateDisplay {.importc: "const struct playdate_display", header: "pd_api.h".} = object
        getWidth {.importsdk.}: proc (): cint
        getHeight {.importsdk.}: proc (): cint
        setRefreshRate {.importsdk.}: proc (rate: cfloat)
        setInvertedRaw {.importc: "setInverted".}: proc (flag: cint) {.cdecl, raises: [].}
        setScale {.importsdk.}: proc (s: cuint)
        setMosaic {.importsdk.}: proc (x: cuint; y: cuint)
        setFlippedRaw {.importc: "setFlipped".}: proc (x: cint; y: cint) {.cdecl, raises: [].}
        setOffset {.importsdk.}: proc (x: cint; y: cint)
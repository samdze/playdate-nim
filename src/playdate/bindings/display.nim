{.push raises: [].}

import utils

sdktype:
    type PlaydateDisplay* {.importc: "const struct playdate_display", header: "pd_api.h".} = object
        # directly mapped to C api
        getWidth {.importsdk.}: proc (): cint
        getHeight {.importsdk.}: proc (): cint
        setScale {.importsdk.}: proc (s: cuint)
        setMosaic {.importsdk.}: proc (x: cuint; y: cuint)
        setOffset* {.importsdk.}: proc (x: cint; y: cint)

        # Called from Nim (src/playdate/display.nim)
        setRefreshRate {.importc: "setRefreshRate".}: proc (rate: cfloat) {.cdecl, raises: [].}
        setInverted {.importc: "setInverted".}: proc (flag: cint) {.cdecl, raises: [].}
        setFlipped {.importc: "setFlipped".}: proc (x: cint; y: cint) {.cdecl, raises: [].}
type
    ConstChar* {.importc: "const char*".} = cstring
    ConstCharPtr* {.importc: "const char**".} = cstring
    Char* {.importc: "char*".} = cstring
    LCDBitmapPtr* {.importc: "LCDBitmap*", header: "pd_api.h".} = pointer

    PDLog* = proc (fmt: ConstChar) {.cdecl, varargs, raises: [].}
        ## The type signature for playdate.system.logToConsole

    PDRealloc* = proc (p: pointer; size: csize_t): pointer {.tags: [], raises: [], cdecl, gcsafe.}
        ## The type signature for playdate.system.realloc
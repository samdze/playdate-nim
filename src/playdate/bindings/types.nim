type ConstChar* {.importc: "const char*".} = cstring
type ConstCharPtr* {.importc: "const char**".} = cstring
type Char* {.importc: "char*".} = cstring

type LCDBitmapPtr* {.importc: "LCDBitmap*", header: "pd_api.h".} = pointer
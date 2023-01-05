{.push raises: [].}

import bindings/types

template toC*(str: typed): untyped =
    cast[Char](str)

template compilerInfo*(): untyped =
    instantiationInfo()
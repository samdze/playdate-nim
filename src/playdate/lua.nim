{.push raises: [].}

import std/importutils

import bindings/[api, system]
import bindings/[types]
import bindings/lua

# Only export public symbols, then import all
export lua
{.hint[DuplicateModuleImport]: off.}
import bindings/lua {.all.}

type LuaError* = object of CatchableError

proc addFunction*(this: ptr PlaydateLua, function: LuaNimFunction, name: string) {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    var err: ConstChar = nil
    var success = this.addFunction(function, name.cstring, addr(err))
    if success == 0:
        raise newException(LuaError, $err)

# registerClass

# indexMetatable

proc getArgCount*(this: ptr PlaydateLua): int =
    privateAccess(PlaydateLua)
    return this.getArgCount().int

proc getArgType*(this: ptr PlaydateLua, position: int): LuaType {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    var cls: ConstChar = nil
    return this.getArgType(position.cint, addr(cls))

proc getArgClass*(this: ptr PlaydateLua, position: int): string {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    var cls: ConstChar = nil
    discard this.getArgType(position.cint, addr(cls))
    return $cls

proc argIsNil*(this: ptr PlaydateLua, position: int): bool {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    return this.argIsNil(position.cint) > 0

proc getArgBool*(this: ptr PlaydateLua, position: int): bool {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    return this.getArgBool(position.cint) > 0

proc getArgFloat*(this: ptr PlaydateLua, position: int): float {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    return this.getArgFloat(position.cint).float

proc getArgInt*(this: ptr PlaydateLua, position: int): int {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    return this.getArgInt(position.cint).int

proc getArgString*(this: ptr PlaydateLua, position: int): string {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    if position < 1 or position > this.getArgCount():
        raise newException(LuaError, "Invalid argument index " & $position & ".")
    return $this.getArgString(position.cint)

# getArgBytes

# getArgObject

# getBitmap

# getSprite

proc pushBool*(this: ptr PlaydateLua, value: bool) =
    privateAccess(PlaydateLua)
    this.pushBool(if value: 1 else: 0)

proc pushInt*(this: ptr PlaydateLua, value: int) =
    privateAccess(PlaydateLua)
    this.pushInt(value.cint)

proc pushFloat*(this: ptr PlaydateLua, value: float) =
    privateAccess(PlaydateLua)
    this.pushFloat(value.cfloat)

proc pushString*(this: ptr PlaydateLua, value: string) =
    privateAccess(PlaydateLua)
    this.pushString(value.cstring)

# pushBytes

# pushBitmap

# pushSprite

# pushObject

# retainObject

# releaseObject

# setUserValue

# getUserValue

proc callFunction*(this: ptr PlaydateLua, name: string, argsCount: int = 0) {.raises: [LuaError]} =
    privateAccess(PlaydateLua)
    privateAccess(PlaydateSys)
    var err: ConstChar = nil
    var success = this.callFunction(name.cstring, argsCount.cint, addr(err))
    if success == 0:
        raise newException(LuaError, $err)
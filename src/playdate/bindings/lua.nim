{.push raises: [].}

import sprite {.all.}
import types

type
    LuaStatePtr* {.importc: "lua_State*".} = object
    LuaNimFunction* = proc (L: LuaStatePtr): cint {.cdecl, raises: [].}
    LuaUDObject* {.importc: "LuaUDObject", header: "pd_api.h", bycopy.} = object

    LValType* {.importc: "l_valtype", header: "pd_api.h".} = enum
        kInt, kFloat, kStr
    
    # LuaReg* {.importc: "lua_reg", header: "pd_api.h", bycopy.} = object
    #     name* {.importc: "name".}: cstring
    #     `func`* {.importc: "func".}: LuaNimFunction

    # LuaType* {.size: sizeof(cint).} = enum
    #     kTypeNil, kTypeBool, kTypeInt, kTypeFloat, kTypeString, kTypeTable,
    #     kTypeFunction,
    #     kTypeThread, kTypeObject
    
    LuaType* {.importc: "enum LuaType", header: "pd_api.h", bycopy.} = enum
        kTypeNil, kTypeBool, kTypeInt, kTypeFloat, kTypeString, kTypeTable,
        kTypeFunction,
        kTypeThread, kTypeObject


type
    # INNER_C_UNION_pd_api_lua_1* {.importc: "lua_val::no_name",
    #                             header: "pd_api.h", bycopy, union.} = object
    #     intval* {.importc: "intval".}: cuint
    #     floatval* {.importc: "floatval".}: cfloat
    #     strval* {.importc: "strval".}: cstring

    # LuaVal* {.importc: "lua_val", header: "pd_api.h", bycopy.} = object
    #     name* {.importc: "name".}: cstring
    #     `type`* {.importc: "type".}: LValType
    #     v* {.importc: "v".}: INNER_C_UNION_pd_api_lua_1

    PlaydateLua* {.importc: "const struct playdate_lua", header: "pd_api.h",
            bycopy.} = object
        ##  these two return 1 on success, else 0 with an error message in outErr
        addFunction {.importc: "addFunction".}: proc (f: LuaNimFunction;
                name: cstring; outErr: ptr cstring): cint {.cdecl, raises: [].}
        # registerClass {.importc: "registerClass".}: proc (name: cstring;
        #         reg: ptr LuaReg; vals: ptr LuaVal;
        #         isstatic: cint; outErr: ptr cstring): cint {.cdecl.}
        pushFunction* {.importc: "pushFunction".}: proc (f: LuaNimFunction) {.cdecl.}
        indexMetatable {.importc: "indexMetatable".}: proc (): cint {.cdecl.}
        stop* {.importc: "stop".}: proc () {.cdecl, raises: [].}
        start* {.importc: "start".}: proc () {.cdecl, raises: [].}
        ##  stack operations
        getArgCount {.importc: "getArgCount".}: proc (): cint {.cdecl, raises: [].}
        getArgType {.importc: "getArgType".}: proc (pos: cint; outClass: ptr cstring): LuaType {.cdecl, raises: [].}
        argIsNil {.importc: "argIsNil".}: proc (pos: cint): cint {.cdecl, raises: [].}
        getArgBool {.importc: "getArgBool".}: proc (pos: cint): cint {.cdecl, raises: [].}
        getArgInt {.importc: "getArgInt".}: proc (pos: cint): cint {.cdecl, raises: [].}
        getArgFloat {.importc: "getArgFloat".}: proc (pos: cint): cfloat {.cdecl, raises: [].}
        getArgString {.importc: "getArgString".}: proc (pos: cint): cstring {.cdecl, raises: [].}
        getArgBytes {.importc: "getArgBytes".}: proc (pos: cint; outlen: ptr csize_t): cstring {.cdecl, raises: [].}
        getArgObject {.importc: "getArgObject".}: proc (pos: cint; `type`: cstring; outud: ptr ptr LuaUDObject): pointer {.cdecl.}
        getBitmap {.importc: "getBitmap".}: proc (pos: cint): LCDBitmapPtr {.cdecl.}
        getSprite {.importc: "getSprite".}: proc (pos: cint): LCDSpritePtr {.cdecl.}
        ##  for returning values back to Lua
        pushNil* {.importc: "pushNil".}: proc () {.cdecl, raises: [].}
        pushBool {.importc: "pushBool".}: proc (val: cint) {.cdecl, raises: [].}
        pushInt {.importc: "pushInt".}: proc (val: cint) {.cdecl, raises: [].}
        pushFloat {.importc: "pushFloat".}: proc (val: cfloat) {.cdecl, raises: [].}
        pushString {.importc: "pushString".}: proc (str: cstring) {.cdecl, raises: [].}
        pushBytes {.importc: "pushBytes".}: proc (str: cstring; len: csize_t) {.cdecl, raises: [].}
        pushBitmap {.importc: "pushBitmap".}: proc (bitmap: LCDBitmapPtr) {.cdecl.}
        pushSprite {.importc: "pushSprite".}: proc (sprite: LCDSpritePtr) {.cdecl.}
        pushObject {.importc: "pushObject".}: proc (obj: pointer; `type`: cstring; nValues: cint): ptr LuaUDObject {.cdecl.}
        retainObject {.importc: "retainObject".}: proc (obj: ptr LuaUDObject): ptr LuaUDObject {.cdecl.}
        releaseObject {.importc: "releaseObject".}: proc (obj: ptr LuaUDObject) {.cdecl.}
        setUserValue {.importc: "setUserValue".}: proc (obj: ptr LuaUDObject; slot: cuint) {.cdecl.}
        ##  sets item on top of stack and pops it
        getUserValue {.importc: "getUserValue".}: proc (obj: ptr LuaUDObject; slot: cuint): cint {.cdecl.}
        ##  pushes item at slot to top of stack, returns stack position
        ##  calling lua from C has some overhead. use sparingly!
        callFunction {.importc: "callFunction".}: proc (name: cstring; nargs: cint;
            outerr: ptr cstring): cint {.cdecl, raises: [].}


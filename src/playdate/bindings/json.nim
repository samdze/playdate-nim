{.push raises: [].}

import strutils

import utils

# Doesn't work
type JSONValueUnion* {.importc: "json_value::no_name", header: "pd_api.h", bycopy, union.} = object
    intval* {.importc: "intval".}: cint
    floatval* {.importc: "floatval".}: cfloat
    stringval* {.importc: "stringval".}: cstring
    arrayval* {.importc: "arrayval".}: pointer
    tableval* {.importc: "tableval".}: pointer

type
    JSONValueType* {.size: sizeof(char).} = enum
        kJSONNull, kJSONTrue, kJSONFalse, kJSONInteger, kJSONFloat, kJSONString,
        kJSONArray, kJSONTable
    JSONValue* {.importc: "json_value", header: "pd_api.h".} = object
        `type`* {.importc: "type".}: JSONValueType
        data* {.importc: "data".}: JSONValueUnion

proc intValue*(this: JsonValue): int {.inline.} =
    case this.type
    of kJSONInteger:
        return this.data.intval
    of kJSONFloat:
        return this.data.floatval.int
    of kJSONString:
        return (try: parseInt($this.data.stringval) except: 0)
    of kJSONTrue:
        return 1
    else:
        return 0

proc floatValue*(this: JSONValue): float {.inline.} =
    case this.`type`
    of kJSONInteger:
        return this.data.intval.float
    of kJSONFloat:
        return this.data.floatval
    of kJSONString:
        return (try: parseFloat($this.data.floatval) except: 0.0)
    of kJSONTrue:
        return 1.0
    else:
        return 0.0

proc boolValue*(this: JSONValue): bool {.inline.} =
    return if this.type == kJSONString: this.data.stringval != "" else: intValue(this) > 0

proc stringValue*(this: JSONValue): string {.inline.} =
    return if this.type == kJSONString: $this.data.stringval else: ""

type JSONDecoder* {.importc: "json_decoder", header: "pd_api.h".} = object
    decodeError* {.importc: "decodeError".}: proc (decoder: ptr JSONDecoder;
        error: cstring; linenum: cint) {.cdecl.} ##  the following functions are each optional
    willDecodeSublist* {.importc: "willDecodeSublist".}: proc (
        decoder: ptr JSONDecoder; name: cstring; `type`: JSONValueType) {.cdecl.}
    shouldDecodeTableValueForKey* {.importc: "shouldDecodeTableValueForKey".}: proc (
        decoder: ptr JSONDecoder; key: cstring): cint {.cdecl.}
    didDecodeTableValue* {.importc: "didDecodeTableValue".}: proc (
        decoder: ptr JSONDecoder; key: cstring; value: JSONValue) {.cdecl.}
    shouldDecodeArrayValueAtIndex* {.importc: "shouldDecodeArrayValueAtIndex".}: proc (
        decoder: ptr JSONDecoder; pos: cint): cint {.cdecl.}
    didDecodeArrayValue* {.importc: "didDecodeArrayValue".}: proc (
        decoder: ptr JSONDecoder; pos: cint; value: JSONValue) {.cdecl.} ##  if pos==0, this was a bare value at the root of the file
    didDecodeSublist* {.importc: "didDecodeSublist".}: proc (
        decoder: ptr JSONDecoder; name: cstring; `type`: JSONValueType): pointer {.
        cdecl.}
    userdata* {.importc: "userdata".}: pointer
    returnString* {.importc: "returnString".}: cint ##  when set, the decoder skips parsing and returns the current subtree as a string
    path* {.importc: "path".}: cstring ##  updated during parsing, reflects current position in tree

type JSONReader* {.importc: "json_reader", header: "pd_api.h".} = object
    read* {.importc: "read".}: proc (userdata: pointer; buf: ptr uint8; bufsize: cint): cint {.
        cdecl.}             ##  fill buffer, return bytes written or -1 on end of data
    userdata* {.importc: "userdata".}: pointer ##  passed back to the read function above

type
    WriteFunc* = proc (userdata: pointer; str: cstring; len: cint) {.cdecl.}
    JSONEncoder* {.importc: "json_encoder", header: "pd_api.h".} = object
        writeStringFunc* {.importc: "writeStringFunc".}: ptr WriteFunc
        userdata* {.importc: "userdata".}: pointer
        pretty* {.importc: "pretty".}: cint
        startedTable* {.importc: "startedTable".}: cint
        startedArray* {.importc: "startedArray".}: cint
        depth* {.importc: "depth".}: cint
        startArray* {.importc: "startArray".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        addArrayMember* {.importc: "addArrayMember".}: proc (encoder: ptr JSONEncoder) {.
            cdecl.}
        endArray* {.importc: "endArray".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        startTable* {.importc: "startTable".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        addTableMember* {.importc: "addTableMember".}: proc (encoder: ptr JSONEncoder;
            name: cstring; len: cint) {.cdecl.}
        endTable* {.importc: "endTable".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        writeNull* {.importc: "writeNull".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        writeFalse* {.importc: "writeFalse".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        writeTrue* {.importc: "writeTrue".}: proc (encoder: ptr JSONEncoder) {.cdecl.}
        writeInt* {.importc: "writeInt".}: proc (encoder: ptr JSONEncoder; num: cint) {.
            cdecl.}
        writeDouble* {.importc: "writeDouble".}: proc (encoder: ptr JSONEncoder;
            num: cdouble) {.cdecl.}
        writeString* {.importc: "writeString".}: proc (encoder: ptr JSONEncoder;
            str: cstring; len: cint) {.cdecl.}

sdktype:
    type PlaydateJSON* {.importc: "const struct playdate_json", header: "pd_api.h".} = object
        initEncoder {.importc: "initEncoder".}: proc (encoder: ptr JSONEncoder;
            write: ptr WriteFunc; userdata: pointer; pretty: cint) {.cdecl, raises: [].}
        decode {.importc: "decode".}: proc (functions: ptr JSONDecoder; reader: JSONReader; outval: ptr JSONValue): cint {.cdecl, raises: [].}
        decodeString {.importc: "decodeString".}: proc (functions: ptr JSONDecoder;
            jsonString: cstring; outval: ptr JSONValue): cint {.cdecl, raises: [].}
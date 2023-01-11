{.push raises: [].}

# import std/importutils
import std/json as nimJSON

# import bindings/[api]
import bindings/json

# Only export public symbols, then import all
export json
{.hint[DuplicateModuleImport]: off.}
import bindings/json {.all.}

type JSONDecoderRes = ref object
    resource: JSONDecoder
    decodeError: proc(this: JSONDecoderRes, error: string, lineNumber: int)
    willDecodeSublist: proc(decoder: JSONDecoderRes; name: cstring; `type`: JSONValueType)

    didDecodeTableValue: proc(decoder: JSONDecoderRes; key: string; value: JSONValue)
    didDecodeArrayValue: proc(decoder: JSONDecoderRes; position: int; value: JSONValue)

proc decodeError(decoder: ptr JSONDecoder; error: cstring; linenum: cint) {.cdecl, raises: [JSONParsingError].} =
    raise newException(JSONParsingError, $error)

proc newJSONDecoder*(this: ptr PlaydateJSON): JSONDecoderRes =
    var res = JSONDecoder()
    res.decodeError = decodeError
    var decoder = JSONDecoderRes(resource: res)
    res.userdata = addr decoder[]
    return decoder

# proc decode*(this: JSONDecoderRes, jsonString: string): JSONValue =
#     privateAccess(PlaydateJSON)
#     var value: JSONValue
#     discard playdate.json.decodeString(addr this.resource, jsonString.cstring, addr value)
#     return value
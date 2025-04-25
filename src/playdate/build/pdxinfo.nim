import std/[os, parsecfg, streams, strutils, strformat, times, osproc, options], nimbledump

type PdxInfo* = object
    ## Details used to populate the pdxinfo file
    name*, author*, description*, bundleId*, imagePath*, version*, buildNumber*: string
    launchSoundPath*, contentWarning*, contentWarning2*: Option[string]

proc isSome(value: string): bool = not value.isEmptyOrWhitespace

proc `$`*(pdx: PdxInfo): string =
    for key, value in pdx.fieldPairs:
        if value.isSome:
            let str = when value is Option: value.get() else: value
            result &= key & "=" & str & "\n"

proc write*(pdx: PdxInfo) =
    ## Writes the pdxinfo file
    createDir("source")
    writeFile("source" / "pdxinfo", $pdx)

proc join*(a, b: PdxInfo): PdxInfo =
    ## Combins two PdxInfo instances
    result = a
    for current, override in fields(result, b):
        if override.isSome:
            current = override

proc parsePdx*(data: Stream, filename: string): PdxInfo =
    ## Parses a pdx config from a string
    let dict = loadConfig(data, filename)
    for key, value in result.fieldPairs:
        let raw = dict.getSectionValue("", key)
        if raw != "":
            value = when typeof(value) is Option: some(raw) else: raw

proc readPdx*(path: string): PdxInfo =
    ## Creates a pdx by reading a local pxinfo file
    if fileExists(path):
        return parsePdx(newFileStream(path), path)

proc gitHashOrElse(fallback: string): string =
    let (output, exitCode) = execCmdEx("git rev-parse HEAD")
    return if exitCode == 0: output[0..<8] else: fallback

proc toPdxInfo*(
    dump: NimbleDump,
    version: string = gitHashOrElse(dump.version),
    buildNumber: string = now().format("yyyyMMddhhmmss")
): PdxInfo =
    ## Creates a base PdxInfo file
    result.name  = dump.name
    result.author = dump.author
    result.description = dump.desc

    let bundleIdPkg = dump.author.toLower().replace(" ", "").replace("-", "").replace("_", "")
    let bundleIdName = dump.name.replace(" ", "").toLowerAscii()
    result.bundleId = fmt"com.{bundleIdPkg}.{bundleIdName}"
    result.imagePath = "launcher"
    result.version = version
    result.buildNumber = buildNumber


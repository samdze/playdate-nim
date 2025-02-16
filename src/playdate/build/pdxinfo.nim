import std/[os, parsecfg, streams, strutils, strformat, times, osproc], nimbledump

type PdxInfo* = object
    ## Details used to populate the pdxinfo file
    name*, author*, description*, bundleId*, imagePath*, version*, buildNumber*: string

proc `$`*(pdx: PdxInfo): string =
    for key, value in pdx.fieldPairs:
        if value != "":
            result &= key & "=" & value & "\n"

proc write*(pdx: PdxInfo) =
    ## Writes the pdxinfo file
    createDir("source")
    writeFile("source" / "pdxinfo", $pdx)

proc join*(a, b: PdxInfo): PdxInfo =
    ## Combins two PdxInfo instances
    result = a
    for current, override in fields(result, b):
        if override != "":
            current = override

proc parsePdx*(data: Stream, filename: string): PdxInfo =
    ## Parses a pdx config from a string
    let dict = loadConfig(data, filename)
    for key, value in result.fieldPairs:
        value = dict.getSectionValue("", key)

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


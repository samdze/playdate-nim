import std/[os, options]

type
    BuildFail* = object of Defect

# This file is used by both nim proper and nimscript. They have different names
# for the `createDir` method, so we need to map between them
when not declared(mkDir):
    template mkDir(dir) = createDir(dir)

const SDK_ENV_VAR* = "PLAYDATE_SDK_PATH"

const playdateSdkPath {.strDefine.} = ""

proc sdkPath*(inputParam: Option[string] = none(string)): string =
    ## Returns the path of the playdate SDK
    let sdkPathCache = getConfigDir() / "playdate-nim" / SDK_ENV_VAR

    if inputParam.isSome:
        result = inputParam.get
    elif playdateSdkPath != "":
        result = playdateSdkPath
    elif getEnv(SDK_ENV_VAR) != "":
        result = getEnv(SDK_ENV_VAR)
    elif sdkPathCache.fileExists:
        result = readFile(sdkPathCache)

    if result == "":
        raise BuildFail.newException("Unable to determine the path to the playdate SDK")

    mkDir(sdkPathCache.parentDir)
    writeFile(sdkPathCache, result)

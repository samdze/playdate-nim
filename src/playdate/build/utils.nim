import sequtils, strutils, os, json

when not compiles(task):
    import system/nimscript

type Target* = enum
    ## Target of the compilation process, simulator or device
    simulator = "simulator"
    device = "device"

type CompileInstructions* = object
    compile: seq[array[2, string]]

type BuildFail* = object of Defect


const SDK_ENV_VAR* = "PLAYDATE_SDK_PATH"


proc nimble*(args: varargs[string]) =
    ## Executes nimble with the given set of arguments
    exec @["nimble"].concat(args.toSeq).join(" ")

proc pdxName*(): string =
    ## The name of the pdx file to generate
    projectDir() & ".pdx"

proc sdkPath*(): string =
    ## Returns the path of the playdate SDK
    let fromEnv = getEnv(SDK_ENV_VAR)
    let sdkPathCache = getConfigDir() / projectName() / SDK_ENV_VAR

    if fromEnv != "":
        mkDir(sdkPathCache.parentDir)
        writeFile(sdkPathCache, fromEnv)
        return fromEnv

    if fileExists(sdkPathCache):
        let fromFile = readFile(sdkPathCache)
        if fromFile != "":
            echo "Read SDK path from file: " & sdkPathCache
            echo "SDK Path: " & fromFile
            return fromFile

    raise BuildFail.newException("SDK environment variable is not set: " & SDK_ENV_VAR)

proc simulatorPath*(open: bool = false): string =
    ## Returns the path of the playdate simulator
    if defined(windows):
        return sdkPath() / "bin" / "PlaydateSimulator.exe"
    elif defined(macosx):
        return (if open: "open " else: "") & sdkPath() / "bin" / "Playdate\\ Simulator.app"
    else:
        return sdkPath() / "bin" / "PlaydateSimulator"

proc pdcPath*(): string =
    ## Returns the path of the pdc playdate utility
    return sdkPath() / "bin" / "pdc"

proc filesToCompile*(target: Target): seq[string] =
    ## Returns the list of C files that have to be compiled
    let jsonString = readFile(nimcacheDir() / $target / projectName() & ".json")
    let instructions = parseJson(jsonString).to(CompileInstructions)

    return instructions.compile.map(
        proc(entry: array[2, string]): string =
            return entry[0]
    )

proc taskArgs*(taskName: string): seq[string] =
    ## Returns the arguments the current task `taskName` has received
    let args = command_line_params()
    let argStart = args.find(taskName) + 1
    return args[argStart..^1]

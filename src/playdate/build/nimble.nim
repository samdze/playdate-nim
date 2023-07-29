import sequtils, strutils, os

# This file is designed to be `included` directly from a nimble file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
    import system/nimscript

proc nimble(args: varargs[string]) =
    ## Executes nimble with the given set of arguments
    exec @["nimble"].concat(args.toSeq).join(" ")

type BuildFail = object of Defect

proc playdatePath(): string =
    ## Returns the path of the playdate nim module
    var (paths, exitCode) = gorgeEx("nimble path playdate")
    paths.stripLineEnd()
    if exitCode != 0:
        raise BuildFail.newException("Could not find the playdate nimble module!")
    let pathsSeq = paths.splitLines(false)
    # If multiple package paths are found, use the last one
    let path = pathsSeq[pathsSeq.len - 1]
    if path.strip == "" or not path.strip.dirExists:
        raise BuildFail.newException("Playdate nimble module is not a directory: " & path)
    return path

proc pdxName(): string =
    ## The name of the pdx file to generate
    projectName() & ".pdx"

const SDK_ENV_VAR = "PLAYDATE_SDK_PATH"

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

proc build(target: string) =
    ## Builds a target
    putEnv(SDK_ENV_VAR, sdkPath())
    putEnv("NIM_CACHE_DIR", nimcacheDir().replace(DirSep, '/'))
    putEnv("PLAYDATE_MODULE_DIR", playdatePath())
    putEnv("PLAYDATE_PROJECT_NAME", projectName())
    putEnv("NIM_INCLUDE_DIR", getCurrentCompilerExe().parentDir.parentDir / "lib")
    
    mkDir("build")
    withDir("build"):
        if target == "simulator":
            if defined(windows):
                exec("cmake --fresh .. -DCMAKE_BUILD_TYPE=Debug" & " -G \"MinGW Makefiles\"")
            else:
                exec("cmake --fresh .. -DCMAKE_BUILD_TYPE=Debug" & " -G \"Unix Makefiles\"")
            exec("make")
        elif target == "device":
            exec("cmake --fresh .. -DCMAKE_BUILD_TYPE=Release" & " -G \"Unix Makefiles\" --toolchain=" & (sdkPath() / "C_API" / "buildsupport" / "arm.cmake"))
            exec("make")

proc cleanCache() =
    rmDir(nimcacheDir())

proc taskArgs(taskName: string): seq[string] =
    let args = command_line_params()
    let argStart = args.find(taskName) + 1
    return args[argStart..^1]


task clean, "Clean the project folders":
    # TODO: clean targets individually
    # let args = taskArgs("clean")
    
    # if args.contains("--all"):
    #     discard
    # elif args.contains("--simulator"):
    #     discard
    # elif args.contains("--device"):
    #     discard
    
    rmDir(nimcacheDir())
    rmDir("build")
    rmDir(pdxName())
    rmFile("Source" / "pdex.bin")
    rmFile("Source" / "pdex.dylib")
    rmFile("Source" / "pdex.dll")
    rmFile("Source" / "pdex.so")
    rmFile("Source" / "pdex.elf")

task cdevice, "Generate C files for the device":
    nimble "-d:device", "build"

task csim, "Generate C files for the simulator":
    nimble "-d:simulator", "build"

task simulator, "Build for the simulator":
    nimble "clean"
    nimble "-d:simulator", "build"
    build "simulator"

task simulate, "Build and run in the simulator":
    nimble "simulator"
    exec( (sdkPath() / "bin" / "PlaydateSimulator") & " " & pdxName())

task device, "Build for the device":
    nimble "clean"
    nimble "-d:device", "build"
    build "device"

task all, "Build for both the simulator and the device":
    nimble "clean"
    nimble "csim"
    build "simulator"
    cleanCache()
    nimble "cdevice"
    build "device"
    # exec(sdkPath() & "/bin/pdc Source " & pdxName())

task setup, "Initialize the build structure":
    ## Creates a default source directory if it doesn't already exist

    # Calling `sdkPath` will ensure the SDK environment variable is saved
    # to the config path
    discard sdkPath()

    if not fileExists("CMakeLists.txt"):
        cpFile(playdatePath() / "CMakeLists.txt", "CMakeLists.txt")
    if not dirExists("Source"):
        mkDir "Source"

    if not fileExists("Source/pdxinfo"):
        let cartridgeName = projectName()
            .replace("_", " ")
            .split(" ")
            .map(proc(s: string): string = s.capitalizeAscii())
            .join(" ")
        let bundleAuthor = author
            .toLower()
            .replace(" ", "")
            .replace("-", "")
            .replace("_", "")
        let bundleProjectName = projectName()
            .toLower()
            .replace(" ", "")
            .replace("-", "")
            .replace("_", "")
        writeFile(
            "Source/pdxinfo",
            [
                "name=" & cartridgeName,
                "author=" & author,
                "description=" & description,
                "bundleId=com." & bundleAuthor & "." & bundleProjectName
            ].join("\n")
        )

    if not fileExists( ".gitignore"):
        ".gitignore".writeFile([
            pdxName(),
            "Source/pdex.*"
        ].join("\n"))

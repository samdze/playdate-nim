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
    let (paths, exitCode) = gorgeEx("nimble path playdate")
    if exitCode != 0:
        raise BuildFail.newException("Could not find the playdate nimble module!")
    let pathsSeq = paths.split("\n")
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

proc make(target: string) =
    ## Executes a make target

    let makefile = playdatePath() & "/playdate.mk"
    if not makefile.fileExists:
        raise BuildFail.newException("Could not find playdate Makefile: " & makefile)

    putEnv(SDK_ENV_VAR, sdkPath())
    putEnv("NIM_CACHE_DIR", nimcacheDir())
    putEnv("PRODUCT", pdxName())
    putEnv("UINCDIR", getCurrentCompilerExe().parentDir.parentDir / "lib")

    let arch = if defined(macosx): "arch -arm64 " else: ""
    exec(arch & "make " & target & " -f " & makefile)

task clean, "Clean the project folders":
    exec "rm -fR " & nimcacheDir()
    make "clean"

task cdevice, "Generate C files for the device":
    nimble "-d:playdate", "build"

task csim, "Generate C files for the simulator":
    nimble "-d:simulator", "build"

task simulator, "Build for the simulator":
    nimble "clean"
    nimble "-d:simulator", "build"
    make "pdc"

task simulate, "Build and run in the simulator":
    nimble "simulator"
    exec( (sdkPath() / "bin" / "PlaydateSimulator") & " " & pdxName())

task device, "Build for the device":
    nimble "clean"
    nimble "-d:playdate", "build"
    make "device"

task all, "Build for both the simulator and the device":
    nimble "clean"
    nimble "csim"
    make "simulator"
    exec "rm -fR " & nimcacheDir()
    nimble "cdevice"
    make "device"
    exec(sdkPath() & "/bin/pdc Source " & pdxName())

task setup, "Initialize the build structure":
    ## Creates a default source directory if it doesn't already exist

    # Calling `sdkPath` will ensure the SDK environment variable is saved
    # to the config path
    discard sdkPath()

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

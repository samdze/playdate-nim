import sequtils, strutils

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
    let (path, exitCode) = gorgeEx("nimble path playdate")
    if exitCode != 0:
        raise BuildFail.newException("Could not find the playdate nimble module!")
    if path.strip == "" or not path.strip.dirExists:
        raise BuildFail.newException("Playdate nimble module is not a directory: " & path)
    return path

proc pdxName(): string =
    ## The name of the pdx file to generate
    projectName() & ".pdx"

proc make(target: string) =
    ## Executes a make target

    let makefile = playdatePath() & "/playdate.mk"
    if not makefile.fileExists:
        raise BuildFail.newException("Could not find playdate Makefile: " & makefile)

    putEnv("PRODUCT", pdxName())
    putEnv("UINCDIR", playdatePath() & "/playdate/include")

    let arch = if defined(macosx): "arch -arm64 " else: ""
    exec(arch & "make " & target & " -f " & makefile)

task cdevice, "build project":
    nimble "-d:playdate", "build"

task csim, "build project":
    nimble "-d:simulator", "build"

task simulator, "build project":
    nimble "clean"
    nimble "-d:simulator", "build"
    make "pdc"

task device, "build project":
    nimble "clean"
    nimble "-d:playdate", "build"
    make "device"

task all, "build all":
    nimble "clean"
    nimble "csim"
    make "simulator"
    exec "rm -fR .nim"
    nimble "cdevice"
    make "device"
    exec(getEnv("PLAYDATE_SDK_PATH") & "/bin/pdc Source " & pdxName())

task clean, "clean project":
    exec "rm -fR .nim"
    make "clean"

import std/[sequtils, strutils, os, strformat, osproc, sets, json]
import utils, pdxinfo, nimbledump

type
    BuildKind* = enum SimulatorBuild, DeviceBuild

    PlaydateConf* {.requiresInit.} = object
        kind*: BuildKind
        sdkPath*, pdxName*: string
        nimbleArgs*: seq[string]
        dump*: NimbleDump
        noAutoConfig*: bool

proc exec*(command: string, args: varargs[string]) =
    ## Executes nimble with the given set of arguments
    let process = startProcess(
        command = command,
        args = args,
        options = {poUsePath, poParentStreams, poEchoCmd}
    )
    if process.waitForExit() != 0:
        raise BuildFail.newException(fmt"Command failed: {command} {args}")

proc nimble*(conf: PlaydateConf, args: varargs[string]) =
    ## Executes nimble with the given set of arguments
    exec(
        "nimble",
        @[ "-d:playdateSdkPath=" & conf.sdkPath ].concat(conf.nimbleArgs).concat(args.toSeq)
    )

proc pdcPath*(conf: PlaydateConf): string =
    ## Returns the path of the pdc playdate utility
    return conf.sdkPath / "bin" / "pdc"

proc fileAppend*(path, content: string) =
    ## Appends a string to a file
    var handle: File
    doAssert handle.open(path, fmAppend)
    try:
        handle.write(content)
    finally:
        handle.close

proc updateGitIgnore(conf: PlaydateConf) =
    ## Adds entries to the gitignore file

    var toAdd = toHashSet([
        conf.pdxName,
        conf.pdxName & ".zip",
        "source/pdxinfo",
        "source/pdex.*",
        "*.dSYM"
    ])

    const gitIgnore = ".gitignore"

    if not fileExists(gitIgnore):
        writeFile(gitIgnore, "")

    for line in lines(gitIgnore):
        toAdd.excl(line)

    if toAdd.len > 0:
        gitIgnore.fileAppend(toAdd.items.toSeq.join("\n"))

proc updateConfig(conf: PlaydateConf) =
    ## Updates the config.nims file for the project if required

    const configFile = "playdate/build/config"

    if fileExists("config.nims"):
        for line in lines("config.nims"):
            if configFile in line:
                echo "config.nims already references ", configFile, "; skipping build configuration"
                return

    echo "Updating config.nims to include build configurations"

    "configs.nims".fileAppend(fmt"\n\n# Added by pdn\nimport {configFile}\n")

proc configureBuild*(conf: PlaydateConf) =
    if not conf.noAutoConfig:
        conf.updateConfig
        echo "Writing pdxinfo"
        conf.dump.toPdxInfo.join(readPdx("./pdxinfo")).write
        echo "Updating gitignore"
        conf.updateGitIgnore

proc bundlePDX*(conf: PlaydateConf) =
    ## Bundles pdx file using parent directory name.
    exec(conf.pdcPath, "--version")
    exec(conf.pdcPath, "--verbose", "-sdkpath", conf.sdkPath, "source", conf.dump.name)

proc mv(source, target: string) =
    echo fmt"Moving {source} to {target}"
    if not source.fileExists and not source.dirExists:
        raise BuildFail.newException(fmt"Expecting the file '{source}' to exist, but it doesn't")
    moveFile(source, target)

proc rm(target: string) =
    echo fmt"Removing {target}"
    removeFile(target)

proc rmdir(target: string) =
    echo fmt"Removing {target}"
    removeDir(target)

proc simulatorBuild*(conf: PlaydateConf) =
    ## Performs a build for running on the simulator

    conf.nimble("build", "-d:simulator", "-d:debug")

    if defined(windows):
        mv(conf.dump.name & ".exe", "source" / "pdex.dll")
    elif defined(macosx):
        mv(conf.dump.name, "source" / "pdex.dylib")
        rmdir("source" / "pdex.dSYM")
        mv(conf.dump.name & ".dSYM", "source" / "pdex.dSYM")
    elif defined(linux):
        mv(conf.dump.name, "source" / "pdex.so")
    else:
        raise BuildFail.newException(fmt"Unsupported host platform")

    conf.bundlePDX()

proc runSimulator*(conf: PlaydateConf) =
    ## Executes the simulator
    simulatorBuild(conf)

    if not conf.pdxName.dirExists:
        raise BuildFail.newException(fmt"PDX does not exist: {conf.pdxName.absolutePath}")

    when defined(windows):
        exec(conf.sdkPath / "bin" / "PlaydateSimulator.exe", conf.pdxName)
    elif defined(macosx):
        exec("open", conf.sdkPath / "bin" / "Playdate Simulator.app", conf.pdxName)
    else:
        exec(conf.sdkPath / "bin" / "PlaydateSimulator", conf.pdxName)

proc deviceBuild*(conf: PlaydateConf) =
    ## Performs a build for running on device

    conf.nimble("build", "-d:device", "-d:release")

    let artifact = when defined(windows): conf.dump.name & ".exe" else: conf.dump.name
    mv(artifact, "source" / "pdex.elf")
    rm("game.map")

    conf.bundlePDX()

    let zip = findExe("zip")
    if zip != "":
        exec(zip, "-r", fmt"{conf.pdxName}.zip", conf.pdxName, "-x", "*.so")

proc runClean*(conf: PlaydateConf) =
    ## Removes all cache files and build artifacts
    rmdir("source" / "pdex.dSYM")
    rm("source" / "pdex.dylib")
    rm("source" / "pdex.dll")
    rm("source" / "pdex.so")
    rm("source" / "pdex.bin")
    rm("source" / "pdex.elf")
    rmdir(conf.pdxName)
    rm("source" / "pdex.elf")
    rm(conf.dump.name)
    rm(conf.dump.name & ".exe")
    exec("nimble", "clean")

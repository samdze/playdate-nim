import std/[parseopt, strutils, os, macros, options]
import playdate/build/[utils, actions, nimbledump]

type
    BuildCommand = enum simulate, simulator, device, clean, bundle
        ## The various actions that can be executed by this script

    CliConfig = object
        ## Configurations collected from the Cli
        command: BuildCommand
        noAutoConfig, showVersion: bool
        sdkPath: Option[string]
        extraArgs: seq[string]

proc getCliConfig(): CliConfig =
    ## Parses the build configuration from the input options
    for kind, key, val in getopt():
        template addExtraArg() =
            var command = if kind == cmdLongOption: "--" else: "-"
            command &= key
            if val != "":
                command &= ":" & val
            result.extraArgs.add(command)

        case kind
        of cmdArgument:
            result.command = parseEnum[BuildCommand](key)
        of cmdLongOption, cmdShortOption:
            case key
            of "sdk-path": result.sdkPath = some(val)
            of "no-auto-config": result.noAutoConfig = true
            of "v", "version": result.showVersion = true
            else: addExtraArg()
        of cmdEnd:
            discard

let build = getCliConfig()

if build.showVersion:
    const NimblePkgVersion {.strdefine.} = ""
    const hash = staticExec("git rev-parse --short HEAD")
    echo "Playdate nim version ", NimblePkgVersion, " ", hash
    quit(QuitSuccess)

let dump = getNimbleDump()

let conf = PlaydateConf(
    dump: dump,
    kind: if build.command == device: DeviceBuild else: SimulatorBuild,
    sdkPath: sdkPath(build.sdkPath),
    pdxName: dump.name & ".pdx",
    nimbleArgs: build.extraArgs,
    noAutoConfig: build.noAutoConfig
)

case build.command
of device, simulate, simulator:
    conf.configureBuild()
of clean, bundle:
    discard

case build.command
of simulator:
    conf.simulatorBuild()
of simulate:
    conf.simulatorBuild()
    conf.runSimulator()
of device:
    conf.deviceBuild()
of clean:
    conf.runClean()
of bundle:
    conf.bundlePDX()

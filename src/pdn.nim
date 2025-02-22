import std/[os, macros, tables], argparse
import playdate/build/[utils, actions, nimbledump]

template read(options, key: untyped; typ: typedesc): auto =
    ## Reads a CLI flag or option. Checks the current subcommand, if available, then checks the parent
    (proc: typ =
        # We use an anonymous proc here because it makes the `when` and `if` expressions inside less complex
        when compiles(options.key):
            if options.key != default(typ):
                return options.key
        when compiles(options.parentOpts.key):
            if options.parentOpts.key != default(typ):
                return options.parentOpts.key
        return default(typ)
    )()

let dump = getNimbleDump()

proc parseConf(kind: BuildKind, options: auto): PlaydateConf =
    # Builds a `PlaydateConf` from the parsed CLI options
    return PlaydateConf(
        dump: dump,
        kind: kind,
        sdkPath: sdkPath(options.read(sdkPath, string)),
        pdxName: dump.name & ".pdx",
        nimbleArgs: options.read(others, seq[string]),
        noAutoConfig: options.read(noAutoConfig, bool)
    )

proc sharedOptions() =
    ## Adds CLI options shared across multiple kinds of builds
    option("--sdk-path", help = "Specifies the location of the Playdate SDK")
    flag("--no-auto-config", help = "Disables editing of config.nims, pdxinfo and .gitignore")

template defineBuild(name: string, kind: BuildKind, action: untyped, helpMessage: string) =
    ## Defines a subcommand that performs a build
    command(name):
        help(helpMessage)
        sharedOptions()
        arg("others", nargs = -1, help = "Extra args are passed to nimble")
        run:
            action(parseConf(kind, opts))

proc showVersion() =
    ## Prints the version number of this script
    const NimblePkgVersion {.strdefine.} = ""
    const hash = staticExec("git rev-parse --short HEAD")
    echo "Playdate nim version ", NimblePkgVersion, " ", hash

var p = newParser:
    help("Nim/Playdate build system")
    flag("-v", "--version", help = "Show pdn version")
    sharedOptions()
    run:
        if opts.version:
            showVersion()
        elif opts.argparse_command == "":
            runSimulator(parseConf(SimulatorBuild, opts))

    defineBuild("simulator", SimulatorBuild, simulatorBuild, "Execute a build for the simulator")
    defineBuild("simulate", SimulatorBuild, runSimulator, "Execute a build and run the simulator")
    defineBuild("device", DeviceBuild, deviceBuild, "Execute a build for device")
    defineBuild("clean", SimulatorBuild, runClean, "Removes build artifacts")
    defineBuild("bundle", SimulatorBuild, bundlePDX, "Executes the bundling step without rebuilding the whole project")

try:
    p.run()
except UsageError as e:
    quit(e.msg, 1)

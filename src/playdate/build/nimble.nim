import sequtils, strutils, os, strformat

import utils

# This file is designed to be `included` directly from a nimble file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
    import system/nimscript


proc bundlePDX() =
    ## Bundles pdx file using parent directory name.
    exec(pdcPath() & " --verbose -sdkpath " & sdkPath() & " source " &
      thisDir().splitPath.tail)

proc postBuild(target: Target) =
    ## Performs post-build cleanup and prepares files for bundling.
    case target:
        of simulator:
            if defined(windows):
                mvFile(projectName() & ".exe", "source" / "pdex.dll")
            elif defined(macosx):
                mvFile(projectName(), "source" / "pdex.dylib")
                rmDir("source" / "pdex.dSYM")
                mvFile(projectName() & ".dSYM", "source" / "pdex.dSYM")
            elif defined(linux):
                mvFile(projectName(), "source" / "pdex.so")
        of device:
            if defined(windows):
                mvFile(projectName() & ".exe", "source" / "pdex.elf")
            else:
                mvFile(projectName(), "source" / "pdex.elf")
            rmFile("game.map")


task clean, "Clean the project files and folders":
    let args = taskArgs("clean")
    # Used to remove debug (_d) and release (_r) cache folders.
    let baseCacheDir = nimcacheDir()[0..^2]
    if args.contains("simulator"):
        rmDir((baseCacheDir & "d") / $Target.simulator)
        rmDir((baseCacheDir & "r") / $Target.simulator)
        rmDir("source" / "pdex.dSYM")
        rmFile("source" / "pdex.dylib")
        rmFile("source" / "pdex.dll")
        rmFile("source" / "pdex.so")
    elif args.contains("device"):
        rmDir((baseCacheDir & "d") / $Target.device)
        rmDir((baseCacheDir & "r") / $Target.device)
        rmFile("source" / "pdex.bin")
        rmFile("source" / "pdex.elf")
    else:
        rmDir((baseCacheDir & "d"))
        rmDir((baseCacheDir & "r"))
        rmDir(nimcacheDir())
        rmDir(pdxName())
        rmDir("source" / "pdex.dSYM")
        rmFile("source" / "pdex.bin")
        rmFile("source" / "pdex.dylib")
        rmFile("source" / "pdex.dll")
        rmFile("source" / "pdex.so")
        rmFile("source" / "pdex.elf")
    rmFile("game.map")
    rmFile(projectName())
    rmFile(projectName() & ".exe")

task simulator, "Build for the simulator":
    let args = taskArgs("simulator")
    if args.contains("release"):
        nimble "-d:simulator", "-d:release", "build", "--verbose"
    else:
        nimble "-d:simulator", "-d:debug", "build", "--verbose"
    postBuild(Target.simulator)
    bundlePDX()

task simulate, "Build and run in the simulator":
    nimble "simulator"
    exec (simulatorPath(open = true) & " " & pdxName())

task device, "Build for the device":
    let args = taskArgs("device")
    if args.contains("debug"):
        nimble "-d:device", "-d:debug", "build", "--verbose"
    else:
        nimble "-d:device", "-d:release", "build", "--verbose"
    postBuild(Target.device)
    bundlePDX()

task all, "Build for both the simulator and the device":
    let args = taskArgs("all")
    var simulatorBuild = "debug"
    var deviceBuild = "release"
    # Only release device build are supported on macOS at the moment.
    if args.contains("debug") and not defined(macosx):
        deviceBuild = "debug"
    elif args.contains("release"):
        simulatorBuild = "release"
    nimble "-d:simulator", fmt"-d:{simulatorBuild}", "build", "--verbose"
    postBuild(Target.simulator)
    nimble "-d:device", fmt"-d:{deviceBuild}", "build", "--verbose"
    postBuild(Target.device)
    bundlePDX()

task setup, "Initialize the build structure":
    ## Creates a default source directory if it doesn't already exist

    # Calling `sdkPath` will ensure the SDK environment variable is saved
    # to the config path
    discard sdkPath()

    if not dirExists("source"):
        mkDir "source"

    if not fileExists("source/pdxinfo"):
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
            "source/pdxinfo",
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
            "source/pdex.*",
            "*.dSYM"
        ].join("\n"))

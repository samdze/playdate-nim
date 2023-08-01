import sequtils, strutils, os

import utils

# This file is designed to be `included` directly from a nimble file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
    import system/nimscript


proc bundlePDX() =
    ## Bundles the pdx file
    exec(pdcPath() & " -sdkpath " & sdkPath() & " source playdate")

proc postBuild(target: Target) =
    case target:
        of simulator:
            if defined(windows):
                mvFile(projectName(), "source" / "pdex.dll")
            elif defined(macosx):
                mvFile(projectName(), "source" / "pdex.dylib")
                rmDir("source" / "pdex.dSYM")
                mvFile(projectName() & ".dSYM", "source" / "pdex.dSYM")
            elif defined(linux):
                mvFile(projectName(), "source" / "pdex.so")
        of device:
            mvFile(projectName(), "source" / "pdex.elf")
            rmFile("game.map")


task clean, "Clean the project files and folders":
    let args = taskArgs("clean")
    
    if args.contains("--simulator"):
        rmDir(nimcacheDir() / $Target.simulator)
        rmDir("build" / $Target.simulator)
        rmDir("source" / "pdex.dSYM")
        rmFile("source" / "pdex.dylib")
        rmFile("source" / "pdex.dll")
        rmFile("source" / "pdex.so")
    elif args.contains("--device"):
        rmDir(nimcacheDir() / $Target.device)
        rmDir("build" / $Target.device)
        rmFile("source" / "pdex.bin")
        rmFile("source" / "pdex.elf")
    else:
        rmDir(nimcacheDir())
        rmDir(pdxName())
        rmDir("build")
        rmDir("source" / "pdex.dSYM")
        rmFile("source" / "pdex.bin")
        rmFile("source" / "pdex.dylib")
        rmFile("source" / "pdex.dll")
        rmFile("source" / "pdex.so")
        rmFile("source" / "pdex.elf")

task simulator, "Build for the simulator":
    nimble "-d:simulator", "build", "--verbose"
    postBuild(Target.simulator)
    bundlePDX()

task simulate, "Build and run in the simulator":
    nimble "simulator"
    exec (simulatorPath(open = true) & " " & pdxName())

task device, "Build for the device":
    nimble "-d:device", "build", "--verbose"
    postBuild(Target.device)
    bundlePDX()

task all, "Build for both the simulator and the device":
    nimble "-d:simulator", "build", "--verbose"
    postBuild(Target.simulator)
    nimble "-d:device", "build", "--verbose"
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

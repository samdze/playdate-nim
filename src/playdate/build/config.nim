import os, strutils

when defined(device):
    import strformat

import utils

# This file is designed to be `included` directly from a `config.nims` file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs.
when not compiles(task):
    import system/nimscript

const headlessTesting = defined(simulator) and declared(test)
const nimbleTesting = not defined(simulator) and not defined(device) and declared(test)
const testing = headlessTesting or nimbleTesting

# Path to the playdate src directory when checked out locally
const localPlaydatePath = currentSourcePath / "../../../../src"

# The path to the nimble playdate package
let nimblePlaydatePath =
    if dirExists(localPlaydatePath / "playdate"):
        localPlaydatePath
    else:
        gorgeEx("nimble path playdate").output.split("\n")[0]

if not testing:
    switch("noMain", "on")
switch("backend", "c")
switch("mm", "arc")
switch("parallelBuild", "0") # Auto-detect
switch("hint", "CC:on")

switch("arm.any.gcc.exe", "arm-none-eabi-gcc")
switch("arm.any.gcc.linkerexe", "arm-none-eabi-gcc")
switch("arm.any.gcc.options.linker", "-static")
switch("clang.options.linker", "")
switch("mingw.options.linker", "")
switch("gcc.options.linker", "")
switch("gcc.options.debug", "-g3 -O0 -gdwarf-3")

switch("passC", "-DTARGET_EXTENSION=1")
switch("passC", "-Wall")
switch("passC", "-Wno-unknown-pragmas")
switch("passC", "-Wdouble-promotion")
switch("passC", "-I" & sdkPath() / "C_API")

switch("os", "any")
switch("define", "useMalloc")
switch("define", "standalone")
switch("threads", "off")

when defined(device):
    switch("gcc.options.always", "")

    switch("nimcache", nimcacheDir() / "device")
    switch("cc", "gcc")
    switch("app", "console")
    switch("cpu", "arm")
    switch("checks", "off")
    switch("assertions", "off")
    switch("hotCodeReloading", "off")

    let heapSize = 8388208
    let stackSize = 61800
    switch("passC", fmt"-D__HEAP_SIZE={heapSize} -D__STACK_SIZE={stackSize}")
    switch("passC", "-DTARGET_PLAYDATE=1")
    switch("passC", "-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16 -D__FPU_USED=1")
    switch("passC", "-falign-functions=16 -fomit-frame-pointer -gdwarf-2 -fverbose-asm")
    switch("passC", "-ffunction-sections -fdata-sections -mword-relocations -fno-common")
    # Disabled warnings
    switch("passC", "-Wno-unused-but-set-variable -Wno-unused-label -Wno-parentheses -Wno-discarded-qualifiers -Wno-array-bounds")

    switch("passL", "-nostartfiles")
    switch("passL", "-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16 -D__FPU_USED=1")
    switch("passL", "-T" & sdkPath() / "C_API" / "buildsupport" / "link_map.ld")
    switch("passL", "-Wl,-Map=game.map,--cref,--gc-sections,--emit-relocs")
    switch("passL", "--entry eventHandlerShim")
    switch("passL", "-lc -lm -lgcc")

    if defined(release):
        switch("define", "release")
        # Normally, one would use opt = speed, which implies O3 (optimization level 3),
        # but O2 outperforms O3 on the Playdate
        switch("opt", "none")
        switch("passC", "-O2")
        switch("debuginfo", "off")
        switch("index", "off")
        switch("stackTrace", "off")
        switch("lineTrace", "off")
        switch("passC", "--specs=nosys.specs")
        switch("passL", "-lnosys --specs=nosys.specs")
    else:
        switch("define", "debug")
        switch("opt", "none")
        switch("debuginfo", "on")
        switch("index", "on")
        switch("stackTrace", "on")
        switch("lineTrace", "on")
        switch("passL", "-lrdimon --specs=rdimon.specs")

when defined(simulator):
    switch("define", "simulator")
    switch("nimcache", nimcacheDir() / "simulator")
    if not testing:
        # Switching to a lib build makes tests not work.
        switch("app", "lib")
    
    if defined(macosx):
        switch("cc", "clang")
        switch("passC", "-arch x86_64 -arch arm64")
        switch("passL", "-arch x86_64 -arch arm64")
    elif defined(linux):
        switch("cc", "gcc")
        switch("passC", "-fPIC")
        switch("passL", "-fPIC")
    elif defined(windows):
        switch("define", "mingw")
        switch("cc", "gcc")
        switch("passC", "-D_WINDLL=1")
    
    switch("checks", "on")
    switch("index", "on")
    switch("debuginfo", "on")
    switch("stackTrace", "on")
    switch("lineTrace", "on")
    switch("lineDir", "on")
    switch("debugger", "native")
    switch("opt", "none")

    switch("define", "debug")

    switch("passC", "-DTARGET_SIMULATOR=1")
    switch("passC", "-Wstrict-prototypes")

if nimbleTesting:
    # Compiling for tests.
    switch("define", "simulator")
    switch("nimcache", nimcacheDir() / "simulator")
    
    if defined(macosx):
        switch("cc", "clang")
        switch("passC", "-arch x86_64 -arch arm64")
        switch("passL", "-arch x86_64 -arch arm64")
    elif defined(linux):
        switch("cc", "gcc")
        switch("passC", "-fPIC")
        switch("passL", "-fPIC")
    elif defined(windows):
        switch("define", "mingw")
        switch("cc", "gcc")
        switch("passC", "-D_WINDLL=1")
    
    switch("checks", "on")
    switch("index", "on")
    switch("debuginfo", "on")
    switch("stackTrace", "on")
    switch("lineTrace", "on")
    switch("lineDir", "on")
    switch("debugger", "native")
    switch("opt", "none")

    switch("define", "debug")
    switch("define", "nimAllocPagesViaMalloc")
    switch("define", "nimPage256")

    switch("passC", "-DTARGET_SIMULATOR=1")
    switch("passC", "-Wstrict-prototypes")
else:
    # Add extra files to compile last, so that
    # they get compiled in the correct nimcache folder.
    # Windows doesn't like having setup.c compiled.
    if defined(device) or not defined(windows):
        switch("compile", sdkPath() / "C_API" / "buildsupport" / "setup.c")

    # Overrides the nim memory management code to ensure it uses the playdate allocator
    patchFile("stdlib", "malloc", nimblePlaydatePath / "playdate/bindings/malloc")
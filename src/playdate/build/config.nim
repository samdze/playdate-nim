import os
when defined(device):
    import strformat

import utils

# This file is designed to be `included` directly from a `config.nims` file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs.
when not compiles(task):
    import system/nimscript

const headlessTesting = defined(simulator) and declared(test)
const nimbleTesting = not defined(simulator) and not defined(devide) and declared(test)
const testing = headlessTesting or nimbleTesting

if not testing:
    switch("noMain", "on")
switch("backend", "c")
switch("mm", "arc")
switch("os", "any")
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

when defined(device):
    switch("gcc.options.always", "")

    switch("nimcache", nimcacheDir() / "device")
    switch("cc", "gcc")
    switch("app", "console")
    switch("cpu", "arm")
    switch("checks", "off")
    switch("threads", "off")
    switch("assertions", "off")
    switch("hotCodeReloading", "off")
    switch("define", "useMalloc")

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
        switch("opt", "speed")
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
    switch("define", "nimAllocPagesViaMalloc")
    switch("define", "nimPage256")

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
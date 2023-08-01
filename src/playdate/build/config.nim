import os, strformat
import utils

# This file is designed to be `included` directly from a `config.nims` file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
    import system/nimscript


switch("mm", "arc")
switch("noMain", "on")
switch("os", "any")

switch("arm.any.gcc.exe", "arm-none-eabi-gcc")
switch("arm.any.gcc.linkerexe", "arm-none-eabi-gcc")
switch("arm.any.gcc.options.linker", "-static")
switch("clang.options.linker", "")
switch("mingw.options.linker", "")
switch("gcc.options.linker", "")

switch("passC", "-DTARGET_EXTENSION=1")
switch("passC", "-Wall")
switch("passC", "-Wno-unknown-pragmas")
switch("passC", "-Wdouble-promotion")
switch("passC", "-I" & sdkPath() / "C_API")

when defined(device):
    switch("nimcache", nimcacheDir() / "device")
    switch("cc", "gcc")
    switch("app", "console")
    switch("cpu", "arm")
    switch("checks", "off")
    switch("opt", "speed")
    switch("debuginfo", "off")
    switch("index", "off")
    switch("threads", "off")
    switch("stackTrace", "off")
    switch("lineTrace", "off")
    switch("assertions", "off")
    switch("hotCodeReloading", "off")

    switch("define", "release")
    switch("define", "useMalloc")

    let heapSize = 8388208
    let stackSize = 61800
    switch("passC", fmt"-D__HEAP_SIZE={heapSize} -D__STACK_SIZE={stackSize}")
    switch("passC", "-DTARGET_PLAYDATE=1")
    switch("passC", "-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16 -D__FPU_USED=1")
    switch("passC", "-falign-functions=16 -fomit-frame-pointer -gdwarf-2 -fverbose-asm")
    switch("passC", "-ffunction-sections -fdata-sections -mword-relocations -fno-common")

    switch("passL", "-nostartfiles")
    switch("passL", "-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16 -D__FPU_USED=1")
    switch("passL", "-T" & sdkPath() / "C_API" / "buildsupport" / "link_map.ld")
    switch("passL", "-Wl,-Map=game.map,--cref,--gc-sections,--no-warn-mismatch,--emit-relocs")
    switch("passL", "--entry eventHandlerShim")
    switch("passL", "-lrdimon -lc -lm -lgcc -lnosys")

when defined(simulator):
    switch("define", "simulator")
    switch("nimcache", nimcacheDir() / "simulator")
    switch("app", "lib")
    
    if defined(macosx):
        switch("cc", "clang")
        switch("passC", "-arch x86_64 -arch arm64")
        switch("passL", "-arch x86_64 -arch arm64")
    elif defined(linux):
        switch("cc", "gcc")
    elif defined(windows):
        switch("cc", "mingw")
    
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

# Add extra files to compile last, so that 
# they get compiled in the correct nimcache folder
switch("compile", sdkPath() / "C_API" / "buildsupport" / "setup.c")
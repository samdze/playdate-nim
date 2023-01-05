# switch("define", "release")
# switch("define", "debug")
# switch("define", "useMalloc")
# switch("define", "checkAbi")
# switch("cincludes", "/Users/sam/Developer/PlaydateSDK/C_API")
switch("mm", "arc")
switch("noMain", "on")
switch("cc", "gcc")
# switch("threads", "off")

# switch("threads", "off")
# switch("stackTrace", "off")
# switch("lineTrace", "off")
# switch("assertions", "off")
# switch("hotCodeReloading", "off")
# switch("index", "off")

switch("compileOnly", "on")
switch("nimcache", ".nim")

# switch("threads", "off")
# switch("define", "useMalloc")
# switch("define", "nimAllocPagesViaMalloc")
# switch("checks", "on")
# switch("os", "any")
# switch("index", "on")
# switch("debuginfo", "on")
# switch("lineTrace", "on")
# switch("debugger", "native")
# switch("opt", "none")
# switch("define", "nimPage512")

when defined(playdate):
    echo "compiling for device"
    switch("define", "release")
    switch("checks", "off")
    switch("cpu", "arm")
    switch("define", "useMalloc")
    switch("opt", "speed")
    switch("os", "any")

    switch("debuginfo", "off")
    switch("index", "off")
    switch("threads", "off")
    switch("stackTrace", "off")
    switch("lineTrace", "off")
    switch("assertions", "off")
    switch("hotCodeReloading", "off")
    switch("debugger", "native")

when defined(simulator):
    echo "compiling for simulator"
    switch("define", "debug")
    switch("define", "nimAllocPagesViaMalloc")
    switch("checks", "on")
    switch("index", "on")
    switch("debuginfo", "on")
    switch("lineTrace", "on")
    switch("lineDir", "on")
    switch("debugger", "native")
    switch("opt", "none")
    switch("define", "nimPage256")
    # switch("os", "any")
    # when defined(macosx):
    #     echo("macos")
    # switch("cpu", "arm64")


# task tests, "run the test":
#     exec "testament pat \"test*.nim\""

task cdevice, "build project":
    exec "nim -d:playdate c src/main.nim"

task csim, "build project":
    exec "nim -d:simulator c src/main.nim"

task simulator, "build project":
    exec "nim clean"
    exec "nim -d:simulator c src/main.nim"
    var arch = ""
    if defined(macosx):
        arch = "arch -arm64 "
    exec arch & "make pdc"

task device, "build project":
    exec "nim clean"
    exec "nim -d:playdate c src/main.nim"
    exec "make device"

task all, "build all":
    exec "nim clean"
    exec "nim csim"
    var arch = ""
    if defined(macosx):
        arch = "arch -arm64 "
    exec arch & "make simulator"
    exec "rm -fR .nim"
    exec "nim cdevice"
    exec "make device"
    exec "${PLAYDATE_SDK_PATH}/bin/pdc Source HelloWorld.pdx"

task clean, "clean project":
    exec "rm -fR .nim"
    exec "make clean"
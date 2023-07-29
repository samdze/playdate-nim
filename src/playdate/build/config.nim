import os

# This file is designed to be `included` directly from a `config.nims` file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
    import system/nimscript

switch("mm", "arc")
switch("noMain", "on")
switch("cc", "gcc")
switch("compileOnly", "on")
switch("nimcache", nimcacheDir())

when defined(device):
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
    switch("define", "simulator")

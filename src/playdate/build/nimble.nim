
# This file is designed to be `included` directly from a nimble file, which will make `switch` and `task`
# implicitly available. This block just fixes auto-complete in IDEs
when not compiles(task):
    import system/nimscript

task simulator, "Build for the simulator":
    exec "pdn simulator"

task simulate, "Build and run in the simulator":
    exec "pdn simulate"

task device, "Build for the device":
    exec "pdn device"

task configure, "Initialize the build structure":
    # No longer required
    discard

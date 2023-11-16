# Nim Playdate ![build workflow](https://github.com/samdze/playdate-nim/actions/workflows/build.yml/badge.svg)
![Playdate Simulator 2023-01-06 at 19 41 01](https://user-images.githubusercontent.com/19392104/211077589-09d1c9ee-02a4-4804-8c2b-6a8ad1850ec3.png)

## About
Playdate Nim bindings, aiming to provide:
- C comparable performance
- Concise and easy syntax
- More ergonomic API over the C API
- Automatic memory management

The main takeaway is that, while this is to some extent a 1 to 1 mapping of the C API, it also adds extra features such as reference counted memory, OOP syntax, many other nice to haves and enhanced developer experience.

The bindings are perfectly usable but a few breaking changes are expected on the road to v1.0.
<hr>

Here's a quick comparison between the main languages usable on the Playdate:
Language | C | Lua | Nim  |
:---- | ---- | ---- | ----
**Performance** | ✔ Great | Decent | ✔ Great
**Memory Management** | ✖ No management | ✔ Garbage collected | ✔ Reference counted
**Memory usage** | ✔ Lowest | Acceptable | ✔ Low
**Typing** | Static | Dynamic | Static
**API** | Low level | High level | Mixed
**Syntax** | Quite easy | ✔ Easiest & concise | ✔ Easy & concise
**Error checking** | Basic compile + runtime | ✖ Mostly runtime | ✔ Compile time + runtime
**OOP** | ✖ Not supported | ✔ Supported | ✔ Supported

This package is an independent bindings library, not affiliated with Panic.

## Getting Started

### Prerequisites

- Playdate SDK
- Nim 1.6.10+ (check with `nim -v`, untested with 2.0+) ([recommended extension for VSCode](https://marketplace.visualstudio.com/items?itemName=nimsaem.nimvscode))
- Nimble 0.13.1 (check with `nimble -v`)
- `PLAYDATE_SDK_PATH` environment variable
- [SDK Prerequisites](https://sdk.play.date/Inside%20Playdate%20with%20C.html#_prerequisites) based on OS, and [MinGW on Windows](https://code.visualstudio.com/docs/cpp/config-mingw).

### Installation

You can quickly start using the bindings opening the `playdate_example` project included in this repository.<br>
If you want to start from scratch, here are the steps to follow:

1. If you haven't done it already, start creating a folder (snake_case) and initializing your nimble package inside it running:

```
nimble init
```
Choose `binary` as the package type.

2. Install the `playdate` package:

```
nimble install playdate
```

3. Add the `playdate` package as a dependency and configure the build tasks by running the following:

```
echo 'requires "playdate"' >> *.nimble;
echo 'include playdate/build/nimble' >> *.nimble;
echo 'include playdate/build/config' > config.nims;
```

4. Finally, run this command to setup the structure of the project, which prepares your application to be compiled and bundled correctly:

```
nimble setup
```

## Usage

If you haven't done it already, install the package:
```
nimble install playdate
```

`playdate_example` contains a basic example of the bindings utilization.
The example code is in `playdate_example/src/playdate_example.nim`.

Here's also a minimal snippet to make a Nim application:
```nim
import playdate/api

var nimLogoBitmap: LCDBitmap

proc update(): int {.raises: [].} =
    nimLogoBitmap.draw(168, 88, kBitmapUnflipped)

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInit:
        # Errors are handled through exceptions, this is an inline try/except
        nimLogoBitmap = try: playdate.graphics.newBitmap("/images/nim_logo") except: nil
        # playdate is the global PlaydateAPI instance, available when playdate/api is imported 
        playdate.system.setUpdateCallback(update)

# Used to setup the SDK entrypoint
initSDK()
```

Compile the project (pdx) for the simulator using:
```sh
nimble simulator
```
For the device (pdx):
```sh
nimble device
```
For simulator + device (pdx):
```sh
nimble all
```

You can also build for simulator and launch it in one command:
```sh
nimble simulate
```

The example project `playdate_example` also contains VSCode launch configurations to build, start and debug your Nim application from the editor.

Each project contains a `config.nims` file that can be edited to customize how the project should be built, e.g. adding libraries or other external code.<br>
Here's an example of a `config.nims` that links a pre-built static library called chipmunk:
```nim
include playdate/build/config

# Add a search path for libraries based on OS.
if defined(device):
    switch("passL", "-L" & getCurrentDir() / "lib" / "device")
elif defined(windows):
    switch("passL", "-L" & getCurrentDir() / "lib" / "windows")
elif defined(macosx):
    switch("passL", "-L" & getCurrentDir() / "lib" / "macos")
elif defined(linux):
    switch("passL", "-L" & getCurrentDir() / "lib" / "linux")
else:
    echo "Platform not supported!"
# Link the chipmunk library.
switch("passL", "-lchipmunk")
```

## Interoperability with Lua

Nim can be used together with Lua.
There are two ways you can use Nim and Lua in the same project:
1. The main loop is defined in Nim, but you want to call a few Lua functions.
2. The main loop is defined in Lua, but you want to call Nim functions.

Either way, you can provide Lua with your Nim functions during Lua initialization:
```nim
proc nimInsideLua(state: LuaStatePtr): cint {.cdecl, raises: [].} = ...

# Application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInitLua: # Lua initialization event
        # Add a function `nimInsideLua` to the Lua environment
        playdate.lua.addFunction(nimInsideLua, "nimInsideLua")
        # If you want to use Nim to define the main loop, set the update callback
        playdate.system.setUpdateCallback(update)
```

Calling a Lua function from Nim:
```nim
try:
    # Push the argument first 
    playdate.lua.pushInt(5)
    playdate.lua.callFunction("funcWithOneArgument", 1)
except:
    playdate.system.logToConsole(getCurrentExceptionMsg())
```

---
This project is a work in progress, here's what is missing right now:
- various playdate.sound funcionalities (but FilePlayer and SamplePlayer are available)
- playdate.json, but you can use Nim std/json, which is very convenient
- advanced playdate.lua features, but basic Lua interop is available
- playdate.scoreboards, undocumented even in the official C API docs

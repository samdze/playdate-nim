# Nim Playdate
![Playdate Simulator 2023-01-06 at 19 41 01](https://user-images.githubusercontent.com/19392104/211077589-09d1c9ee-02a4-4804-8c2b-6a8ad1850ec3.png)

## About
Playdate Nim bindings, aiming to provide:
- C comparable performance
- Concise and easy syntax
- More ergonomic API over the C API
- Automatic memory management

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

## Getting Started

At the moment, this is just a template that contains the required code to wrap and use the Playdate SDK in Nim.

The bindings will become a Nim package when stable enough.

### Prerequisites

- Playdate SDK
- Nim 1.6.10+
- `PLAYDATE_SDK_PATH` environment variable

## Usage

`src/main.nim` contains a basic example of the bindings utilization.

A pre-compiled pdx is also provided, please test it on your device!

Compile the project (pdx) for the simulator using:
```sh
nim simulator
```
For the device (compile only, no pdx):
```sh
nim device
```
For simulator + device (pdx):
```sh
nim all
```

The template also has a VSCode launch configuration file to build, start and debug the Nim application from the editor.

---
This is still a work in progress, here's what is available right now:
- playdate.system (inputs, menu items, log, etc.)
- playdate.graphics (draw stuff)
- playdate.display (general screen stuff)
- playdate.file (read, write and create files and folders)
- playdate.sprite (draw sprites and handle collisions)
- (partial) playdate.sound (play sounds and music)
- json encoding/decoding, through Nim std/json

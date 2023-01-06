# Nim Playdate
![Playdate Simulator 2023-01-06 at 19 41 01](https://user-images.githubusercontent.com/19392104/211077589-09d1c9ee-02a4-4804-8c2b-6a8ad1850ec3.png)

## About
Playdate Nim bindings, aiming to provide:
- C comparable performance
- Concise and easy syntax
- More ergonomic API over the C API
- Automatic memory management

Here's a quick comparisons between the main languages usable on the Playdate:
Language | Performance | Memory Management | Memory usage | Typing | API | Syntax
---- | ---- | ---- | ---- | ---- | ---- | ----
C | ✔ Great | ✖ No management | ✔ Lowest | Static | Low level | Quite easy
Lua | Decent | ✔ Garbage collected | Acceptable | Dynamic | High level | ✔ Easiest & concise
Nim | ✔ Great | ✔ Reference counted | ✔ Low | Static | Mixed | ✔ Easy & concise

## Getting Started

At the moment, this is just a template that contains the required code to wrap and use the Playdate SDK in Nim.

The bindings will become a Nim package when stable enough.

### Prerequisites

- Playdate SDK
- Nim 1.6.10+
- `PLAYDATE_SDK_PATH` environment variable

## Usage

`src/main.nim` contains a basic example of the bindings utilization.

Compile the project for the simulator using:
```sh
nim simulator
```
For the device:
```sh
nim simulator
```
For simulator + device:
```sh
nim all
```

The template also has a VSCode launch configuration file to build, start and debug the Nim application from the editor.

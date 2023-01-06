# Nim Playdate
![Playdate Simulator 2023-01-06 at 19 41 01](https://user-images.githubusercontent.com/19392104/211077589-09d1c9ee-02a4-4804-8c2b-6a8ad1850ec3.png)

Playdate Nim bindings, aiming to provide:
- C comparable performance
- Python like syntax (well, Nim syntax)
- More ergonomic API over the C API
- Automatic memory management

Here's a quick comparisons between the main languages usable on the Playdate:
Language | Performance | Memory management | Typing | API | Syntax
---- | ---- | ---- | ---- | ---- | ----
C | ✔ Great | ✖ | Static | Low level | Quite easy
Lua | Decent | ✔ Garbage collected | Dynamic | High level | ✔ Easiest & concise
Nim | ✔ Great | ✔ Reference counted | Static | Mixed | ✔ Easy & concise

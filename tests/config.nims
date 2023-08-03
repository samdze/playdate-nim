# Hack to pretend this is not a lib, the config file checks if test is declared.
proc test*() = discard
include ../src/playdate/build/config

# if headless testing, switch noMain off to include required symbols.
if defined(simulator):
    switch("noMain", "off")
# Make the tests use the local playdate package.
switch("path", projectDir() / ".." / "src")
# This tests package fakes it's not a lib but it actually is.
if defined(simulator):
    switch("passL", "-shared")
# Reset the os to its real value to make the tests run.
if defined(windows):
    switch("os", "windows")
elif defined(macosx):
    switch("os", "macosx")
elif defined(linux):
    switch("os", "linux")
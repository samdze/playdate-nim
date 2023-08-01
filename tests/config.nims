import os

import ../src/playdate/build/utils

switch("compileOnly", "off")
switch("noMain", "off")
switch("path", "$projectDir/../src")
switch("passC", "-I" & sdkPath() & "/C_API -DTARGET_EXTENSION=1")
switch("define", "simulator")
switch("nimcache", nimcacheDir() / "simulator")
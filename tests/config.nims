import ../src/playdate/build/nimble
switch("compileOnly", "off")
switch("noMain", "off")
switch("path", "$projectDir/../src")
switch("passC", "-I" & sdkPath() & "/C_API -DTARGET_EXTENSION=1")
switch("define", "simulator")
# begin Nimble config (version 2)

# allow imports relative to the src/playdate folder from anywhere
# ie. import domain/lcdbitmap
--path:"./src/playdate"

when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

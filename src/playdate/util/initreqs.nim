##
## Contains direct references to playdate apis that are required to be usable before the
## full API is itself available.
##
## This file gets used _very_ early in the Nim initialization process. That means it gets
## imported and used before most of the Nim stdlib is available, so it needs to be almost
## completely self contained.
##

import ../bindings/types

var pdrealloc*: PDRealloc
var pdlog*: PDLog

proc initPrereqs*(realloc: PDRealloc, log: PDLog) =
    ## Sets pointers to functions from the playdate stdlib that are needed to initialize Nim integrations
    log("Initializing Nim playdate globals")
    pdrealloc = realloc
    pdlog = log

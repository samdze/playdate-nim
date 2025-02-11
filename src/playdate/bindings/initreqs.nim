##
## Contains direct references to playdate apis that are required to be usable before the
## full API is itself available.
##

var pdrealloc*: proc (p: pointer; size: csize_t): pointer {.tags: [], raises: [], cdecl, gcsafe.}

proc initPrereqs*(realloc: auto) =
    ## Sets pointers to functions that are needed early in the initialization process
    pdrealloc = realloc

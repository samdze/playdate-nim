import std/[strutils, strformat, osproc, json, jsonutils], utils

type
    NimbleDump* = ref object
        ## The data pulled from running `nimble dump --json`
        name*, version*, nimblePath*, author*, desc*, license*: string

proc getNimbleDump*(): NimbleDump =
    ## Executes nimble with the given set of arguments
    let (output, exitCode) = execCmdEx("nimble dump --json")
    if exitCode != 0:
        echo output
        raise BuildFail.newException(fmt"Unable to extract nimble dump for package")
    return parseJson(output).jsonTo(NimbleDump, Joptions(allowExtraKeys: true))
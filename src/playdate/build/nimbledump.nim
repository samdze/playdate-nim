import std/[strutils, strformat, osproc, json, jsonutils], utils

type NimbleDump* = ref object ## The data pulled from running `nimble dump --json`
  name*, version*, nimblePath*, author*, desc*, license*: string
  entryPoints*: seq[string]

proc getNimbleDump*(): NimbleDump =
  ## Executes nimble with the given set of arguments
  let (output, exitCode) = execCmdEx("nimble dump --json")
  if exitCode != 0:
    echo output
    raise BuildFail.newException(fmt"Unable to extract nimble dump for package")
  try:
    return parseJson(output).jsonTo(NimbleDump, Joptions(allowExtraKeys: true))
  except CatchableError as e:
    echo fmt"Unable to parse nimble dump: {e.msg}"
    echo output
    raise BuildFail.newException("Failed to parse nimble dump output")

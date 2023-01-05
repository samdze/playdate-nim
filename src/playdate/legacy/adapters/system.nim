{.push raises: [].}

import ../bindings/api

type PDCallbackFunction* = proc(api: PlaydateAPI): int {.raises: [].}
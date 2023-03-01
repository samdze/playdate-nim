import macros, options

proc realloc*(p: pointer, size: csize_t): pointer {.importc: "realloc", cdecl.}

func toNimSymbol(typeSymbol: string): string =
    case typeSymbol:
        of "cint":
            return "int"
        of "cuint":
            return "uint"
        of "cstring":
            return "string"
        of "cfloat":
            return "float"
        of "csize_t":
            return "uint"
    return typeSymbol

func toNimReturn(typeSymbol: string, call: NimNode): seq[NimNode] =
    let newTypeSymbol = toNimSymbol(typeSymbol)
    case typeSymbol:
        of "cint", "cuint", "cfloat", "csize_t":
            return @[nnkReturnStmt.newTree(
                nnkCall.newTree(
                    newIdentNode(newTypeSymbol),
                    call
                )
            )]
        of "cstring":
            return @[newIdentNode("$"), call]
        else:
            return @[call]

func adjustRawProcIdentDef(identDef: NimNode, rawProcName: string, procName: string): NimNode =
    let identDef = identDef.copy()

    var pragmas = identDef.findChild(it.kind == nnkProcTy)
        .findChild(it.kind == nnkPragma)
    if pragmas == nil:
        pragmas = nnkPragma.newTree()

    var toAddPragmas = newSeq[NimNode]()
    for pragma in pragmas:
        # Removing invalid pragmas.
        if pragma.kind == nnkIdent and pragma.strVal == "discardable":
            continue
        toAddPragmas.add(pragma)

    var adjustedPragmas = nnkPragma.newTree(
        toAddPragmas
    )
    adjustedPragmas.add(newIdentNode("cdecl"),
        nnkExprColonExpr.newTree(
            newIdentNode("raises"),
            nnkBracket.newTree()
        )
    )

    return nnkIdentDefs.newTree(
        # Add ident pragmas.
        nnkPragmaExpr.newTree(
            newIdentNode(rawProcName),
            nnkPragma.newTree(
                nnkExprColonExpr.newTree(
                    newIdentNode("importc"),
                    newLit(procName)
                )
            )
        ),
        nnkProcTy.newTree(
            # Add params.
            identDef
                .findChild(it.kind == nnkProcTy)
                .findChild(it.kind == nnkFormalParams),
            # Add proc type pragmas.
            adjustedPragmas
        ),
        newEmptyNode()
    )

proc generateSDKPtrProcDef*(rawProcDef: NimNode, rawProcName: string, typeName: string, procName: string): NimNode =
    # echo "RAW PROC GEN: ", rawProcDef.astGenRepr
    var newProcPragmas: NimNode
    var newPragmas = newSeq[NimNode]()

    var newProcParams = nnkFormalParams.newTree()
    let newCall = nnkCall.newTree(
        nnkDotExpr.newTree(
            newIdentNode("this"),
            newIdentNode(rawProcName)
        )
    )

    let fromPragmas = rawProcDef[1].findChild(it.kind == nnkPragma)
    if fromPragmas != nil:
        for pragma in fromPragmas.items:
            if pragma.kind == nnkIdent and pragma.strVal == "cdecl":
                continue
            if pragma.kind == nnkExprColonExpr and pragma[0].strVal == "importc":
                continue
            newPragmas.add(pragma)

    if newPragmas.len > 0:
        newProcPragmas = nnkPragma.newTree(newPragmas)
    else:
        newProcPragmas = newEmptyNode()

    let fromParams = rawProcDef[1].findChild(it.kind == nnkFormalParams)

    # Prepare arguments and return type of the new proc and of the inner call.
    for param in fromParams.items:
        if param.kind == nnkEmpty:
            # Found and adding empty return type and "this: Type" as the first argument
            newProcParams.add(
                newEmptyNode(),
                nnkIdentDefs.newTree(
                    newIdentNode("this"),
                    nnkPtrTy.newTree(
                        newIdentNode(typeName)
                    ),
                    newEmptyNode()
                )
            )
        elif param.kind == nnkIdent:
            # Found a return type
            let typeSymbol = toNimSymbol(param.strVal)
            # Adding return type
            newProcParams.add(newIdentNode(typeSymbol))
            # Adding "this: Type" as the first argument
            newProcParams.add(
                nnkIdentDefs.newTree(
                    newIdentNode("this"),
                    nnkPtrTy.newTree(
                        newIdentNode(typeName)
                    ),
                    newEmptyNode()
                )
            )
        elif param.kind == nnkIdentDefs:
            let oldTypeSymbol = param[1].strVal
            let typeSymbol = toNimSymbol(oldTypeSymbol)
            let argumentName = param[0].strVal
            var argExpr = newIdentNode(argumentName)

            # TODO: Have to check if the parameter is a value, a ptr or a ref.

            if typeSymbol != oldTypeSymbol:
                argExpr = nnkDotExpr.newTree(
                    newIdentNode(argumentName),
                    newIdentNode(oldTypeSymbol)
                )
            let identDefs = nnkIdentDefs.newTree(
                newIdentNode(param[0].strVal),
                newIdentNode(typeSymbol),
                newEmptyNode()
            )

            newCall.add(argExpr)
            newProcParams.add(identDefs)

    # Prepare the return/call statement.
    var newStatmList = nnkStmtList.newTree()
    # echo "CONSTR STMT FROM PARAMS: ", fromParams.astGenRepr

    for param in fromParams.items:
        if param.kind == nnkEmpty:
            # No return, just use the call.
            newStatmList.add(newCall)
        elif param.kind == nnkIdent:
            let oldTypeSymbol = param.strVal
            let nodes = toNimReturn(oldTypeSymbol, newCall)
            newStatmList.add(nodes)

    let procDef = nnkProcDef.newTree(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(procName),
        ),
        newEmptyNode(),
        newEmptyNode(),
        newProcParams,
        newProcPragmas,
        newEmptyNode(),
        newStatmList
    )
    # echo "RETURN / CALL: ", procDef.astGenRepr
    result = procDef

proc processSDKType(ast: NimNode): NimNode =
    # New procedures that will get created after the object definition.
    var generatedProcs: seq[NimNode] = @[]

    # echo "initial arg: ", arg.astGenRepr
    # echo "initial AST: ", ast.astGenRepr
    # echo "initial repr: ", ast.repr

    var newAst = ast.copy()

    var typeName: string
    # var rawTypeName: string
    var typeNode = newAst[0][0]

    if typeNode[0].kind == nnkPragmaExpr:
        typeNode = typeNode[0]

    if typeNode[0].kind == nnkIdent:
        typeName = typeNode[0].strVal
    elif typeNode[0].kind == nnkPostfix:
        typeName = typeNode[0][1].strVal

    # echo "TYPE NAME IDENT: ", typeNameIdent.repr

    var recList = newAst[0][0]
        .findChild(it.kind == nnkObjectTy)
        .findChild(it.kind == nnkRecList)

    for index, identDef in recList:
        # echo "id ", index, " first child type ", identDef[0].kind
        if identDef[0].kind == nnkPragmaExpr:
            let identAndPragmas = identDef[0]
            for idOrPragma in identAndPragmas:
                # echo "- idOrPragma type ", idOrPragma.kind
                if idOrPragma.kind == nnkPragma and idOrPragma[0].kind == nnkIdent:
                    # echo "-- with strVal: ", idOrPragma[0].strVal
                    if idOrPragma[0].strVal == "importsdk" and identDef[1].kind == nnkProcTy:
                        # echo "-- now adapting the def:\n", identDef.astGenRepr
                        var procName: string
                        let identProcName = identDef.findChild(it.kind == nnkPragmaExpr).findChild(it.kind == nnkIdent)
                        if identProcName != nil:
                            procName = identProcName.strVal
                        else:
                            procName = identDef.findChild(it.kind == nnkPragmaExpr)
                                .findChild(it.kind == nnkPostfix)[1].strVal
                        let rawProcName = procName# & "Raw"
                        let adjustedRawProcIdentDef = adjustRawProcIdentDef(identDef, rawProcName, procName)
                        # echo "--- adjusted def ast:\n", adjustedRawProcIdentDef.astGenRepr
                        # echo "--- adjusted def repr:\n", adjustedRawProcIdentDef.repr
                        recList[index] = adjustedRawProcIdentDef
                        let generatedProcDef = generateSDKPtrProcDef(identDef, rawProcName, typeName, procName)
                        # echo "--- generated proc ast:\n", generatedProcDef.astGenRepr
                        # echo "--- generated proc repr:\n", generatedProcDef.repr
                        generatedProcs.add(generatedProcDef)

    for generatedProc in generatedProcs:
        newAst.add(generatedProc)

    result = newAst
    # echo "updated type AST: ", result.astGenRepr
    # echo "updated repr: ", result.repr

macro sdktype*(ast: untyped): untyped =
    return processSDKType(ast)

proc propName(node: NimNode): string =
    ## Returns the name of an object property, given the IdentDef node of that ojbect
    case node.kind
    of nnkIdentDefs, nnkPragmaExpr:
        return node[0].propName
    of nnkPostfix:
        if node[0].propName == "*":
            return node[1].propName
    of nnkIdent:
        return node.strVal
    else: discard
    error("Could not determine node name for: " & node.lispRepr, node)

proc findObjectProp(objType: NimNode, name: string): NimNode =
    ## Searches an object type definition to extract a specific property
    case objType.kind
    of nnkObjectTy:
        for identDef in objType[2]:
            if identDef.propName == name:
                return identDef
        error("Could not find a parameter named " & name, objType)
    of nnkTypeDef:
        return findObjectProp(objType[2], name)
    else:
        error("Node is not an object type: " & $objType.kind, objType)

type Param = tuple[ident: NimNode, typ: NimNode]

proc collectParams(procTy: NimNode): seq[Param] =
    ## Returns a list of parameter names for a proc type.
    for identDefs in procTy.params[1..^1]:
        let typ = identDefs[^2]
        for ident in identDefs[0..^3]:
            result.add((ident, typ))

proc unwrapType(typ: NimNode): NimNode =
    ## Strips any wrapping annotations from a type to get down to the core type node. For example, removes
    ## `var` and `ptr` prefixes.
    case typ.kind
    of nnkIdent, nnkSym: return typ
    of nnkPtrTy, nnkVarTy: return typ[0].unwrapType
    else: error("Unable to unwrap type: " & typ.lispRepr, typ)

proc createCast(expression, inputType, outputType: NimNode): NimNode =
    ## Creates a casting expression to convert a NimNode from one type to another.
    if outputType.kind in { nnkIdent, nnkSym } and outputType.unwrapType.strVal != inputType.unwrapType.strVal:
        return newCall("to_" & outputType.unwrapType.strVal, expression)
    else:
        return expression

proc dotChain(props: varargs[string]): NimNode =
    ## Given a list of strings, produce dot expressions that chain them. For example: playdate.sound.fileplayer.
    for i, prop in props:
        result = if i == 0: ident(prop) else: newDotExpr(result, ident(prop))

proc getSdkRef(typ: NimNode): Option[NimNode] =
    ## Given an SDK type node, returns the reference needed to access the global instance of that type
    ## For example, given "PlaydateGraphics", returns "graphics".
    case typ.unwrapType.strVal
    of "PlaydateDisplay": return some(dotChain("playdate", "display"))
    of "PlaydateGraphics": return some(dotChain("playdate", "graphics"))
    of "PlaydateSys": return some(dotChain("playdate", "system"))
    of "PlaydateSprite": return some(dotChain("playdate", "sprite"))
    of "PlaydateSound": return some(dotChain("playdate", "sound"))
    of "PlaydateSoundFileplayer": return some(dotChain("playdate", "sound", "fileplayer"))
    of "PlaydateSoundSampleplayer": return some(dotChain("playdate", "sound", "sampleplayer"))
    of "PlaydateSoundSample": return some(dotChain("playdate", "sound", "sample"))

proc requireSdkRef(api: NimNode): NimNode =
    ## Returns the global reference to an SDL type, or fails the build if it isn't available
    let prop = api.getSdkRef
    if prop.isSome:
        return prop.unsafeGet
    else:
        error("Unrecognized API binding type: " & api.repr, api)

proc getParamBinding(inputParams: seq[Param]): Option[Param] =
    ## Examines a parameter list and determines whether the first parameter is a binding or not.
    if inputParams.len > 0:
        if inputParams[0].typ.getSdkRef.isSome:
            return some(inputParams[0])

proc buildApiCall(pdApiObjName, pdApiProcName, def: NimNode): NimNode =
    ## Constructs a call to the wrapped API. Returns the call itself.
    ## * `pdApiObjName` is the name of the SDK object this proc is a member of, for example `PlaydateGraphics`
    ## * `pdApiProcName` is the name of the specific SDK proc being wrapped. For example, `logToConsole`
    ## * `def` is the proc definition node for the external proc being created

    pdApiObjName.expectKind(nnkSym)
    pdApiProcName.expectKind(nnkIdent)
    def.expectKind(nnkProcDef)

    # Find the proc we're wrapping on the graphics API
    let apiParam = pdApiObjName.getImpl.findObjectProp(pdApiProcName.strVal)

    # Extract the type from the playdate API proc that we're wrapping
    let apiProc = apiParam[^2]
    apiProc.expectKind(nnkProcTy)

    # A list of parameters from the public proc being defined
    var inputParams = def.collectParams()

    # Some of the public procs will include the "binding" object in the parameter set. For example,
    # a parameter like `ptr PlaydateGraphics`. Other public procs will have a more specific binding, like
    # `LCDSprite`, and need to manually reference the global binding instance (`playdate.graphics`).
    let paramBinding = inputParams.getParamBinding
    let bindTo = if paramBinding.isSome:
        inputParams = inputParams[1..^1]
        paramBinding.unsafeGet.ident
    else:
        pdApiObjName.requireSdkRef()

    # Pass the parameters from the public function along to the Playdate internal API,
    # while converting each parameter to the appropriate type
    var args: seq[NimNode]
    for i, apiParam in apiProc[0][1..^1]:
        apiParam.expectKind(nnkIdentDefs)
        args.add(createCast(inputParams[i].ident, inputParams[i].typ, apiParam[^2]))

    result = newCall(newDotExpr(bindTo, pdApiProcName), args)

    # If the API has a return type, we need to cast the return type to the output type of the proc
    let apiReturnType = apiParam[1][0][0]
    if apiReturnType.kind != nnkEmpty:
        if def.params[0].kind == nnkEmpty:
            result = nnkDiscardStmt.newTree(result)
        else:
            result = nnkReturnStmt.newTree(createCast(result, apiReturnType, def.params[0]))

proc buildApiProc(apis: NimNode, pdApiProcName, def: NimNode): NimNode =
    ## Constructs the public API proc based on the internal playdate API proc
    def.body = newStmtList()

    var apiList = if apis.kind == nnkSym: nnkBracketExpr.newTree(apis) else: apis

    for api in apiList:
        def.body.add quote do: privateAccess(`api`)

    def.body.add(buildApiCall(apiList[0], pdApiProcName, def))
    return def

macro wrapApi*(pdApiObjNames: typed, pdApiProcName, def: untyped): untyped =
    ## Wraps an API call
    ## For example: `{.wrapApi(PlaydateSystem, logToConsole).}`
    buildApiProc(pdApiObjNames, pdApiProcName, def)

macro wrapApi*(pdApiObjNames: typed, def: untyped): untyped =
    ## Wraps an API call that requires multiple permissions, where the name of the API is the name of the method.
    ## For example: `{.wrapApi(PlaydateGraphics).}`
    buildApiProc(pdApiObjNames, def.name, def)


##
## A bunch of common casting functions that are used by the automatically wrapped APIs
##

proc toCstring*(value: string): cstring = cstring(value)

proc toBool*(value: cint): bool = value == 1

proc toCint*(value: SomeInteger | bool): cint =
    when value is bool: return if value: 1 else: 0
    else: return cint(value)

proc toCFloat*(value: SomeFloat): cfloat = cfloat(value)

proc toString*(value: cstring): string = $value

proc toInt*(value: cint): int = int(value)

proc toUInt32*(value: char): uint32 = uint32(value)

proc toUInt*(value: cint | SomeInteger): uint = uint(value)

proc toFloat*(value: cfloat): float = float(value)
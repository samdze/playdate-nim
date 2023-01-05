import macros

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

macro sdkproc*(procedure: typedesc, newName: static[string]): untyped =
    let typeName = procedure[0].strVal
    let procName = procedure[1].strVal
    # echo "AST GEN: ", procedure.astGenRepr
    # echo "AST REPR: ", procedure.getTypeInst.repr
    # echo "AST INST GEN: ", procedure.getTypeInst.astGenRepr
    # echo "AST INST TREE: ", procedure.getTypeInst.treeRepr

    var newProcPragmas = newEmptyNode()
    var newProcParams = nnkFormalParams.newTree()
    let newCall = nnkCall.newTree(
        nnkDotExpr.newTree(
            newIdentNode("this"),
            newIdentNode(procName)
        )
    )
    
    let fromPragmas = procedure.getTypeInst[1].findChild(it.kind == nnkPragma)
    if fromPragmas != nil:
        var newPragmas = newSeq[NimNode]()
        for pragma in fromPragmas.items:
            if pragma.kind == nnkIdent and pragma.strVal == "cdecl":
                continue
            if pragma.kind == nnkExprColonExpr and pragma[0].strVal == "importc":
                continue
            newPragmas.add(pragma)

        if newPragmas.len > 0:
            newProcPragmas = nnkPragma.newTree(newPragmas)

    let fromParams = procedure.getTypeInst[1].findChild(it.kind == nnkFormalParams)
        
    # Prepare arguments and return type of the new proc and of the inner call.
    for param in fromParams.items:
        if param.kind == nnkEmpty:
            # Adding empty return type and this: Type as the first argument
            newProcParams.add(
                newEmptyNode(),
                nnkIdentDefs.newTree(
                    newIdentNode("this"),
                    newIdentNode(typeName),
                    newEmptyNode()
                )
            )
        elif param.kind == nnkSym:
            let typeSymbol = toNimSymbol(param.strVal)
            # Adding return type
            newProcParams.add(newIdentNode(typeSymbol))
            # Adding "this: Type" as the first argument
            newProcParams.add(
                nnkIdentDefs.newTree(
                    newIdentNode("this"),
                    newIdentNode(typeName),
                    newEmptyNode()
                )
            )
        elif param.kind == nnkIdentDefs:
            let oldTypeSymbol = param[1].strVal
            let typeSymbol = toNimSymbol(oldTypeSymbol)
            let argumentName = param[0].strVal
            var argExpr = newIdentNode(argumentName)

            # TODO: Have to check if the parameter is a value, a ptr or a ref.

            var identDefs: NimNode# = param.copy()
            if typeSymbol != oldTypeSymbol:
                argExpr = nnkDotExpr.newTree(
                    newIdentNode(argumentName),
                    newIdentNode(oldTypeSymbol)
                )
            identDefs = nnkIdentDefs.newTree(
                newIdentNode(param[0].strVal),
                newIdentNode(typeSymbol),
                newEmptyNode()
            )
            
            newCall.add(argExpr)
            newProcParams.add(identDefs)

    # Prepare the return/call statement.
    var newStatmList = nnkStmtList.newTree(
        nnkCall.newTree(
            newIdentNode("privateAccess"),
            newIdentNode(typeName)
        )
    )
    for param in fromParams.items:

        if param.kind == nnkEmpty:
            # No return, just use the call.
            newStatmList.add(newCall)

        elif param.kind == nnkSym:
            let oldTypeSymbol = param.strVal
            let nodes = toNimReturn(oldTypeSymbol, newCall)
            newStatmList.add(nodes)

    let procDef = nnkProcDef.newTree(
        nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(newName),
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


proc generateSDKProcDef*(rawProcDef: NimNode, rawProcName: string, typeName: string, procName: string): NimNode =
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
                    newIdentNode(typeName),
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
                    newIdentNode(typeName),
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

# proc generateProcDef(rawProcRef: NimNode, rawProcName: string, procName: string): NimNode =
#     result = nnkProcDef.newTree(
#         newIdentNode(procName),
#         newEmptyNode(),
#         newEmptyNode(),
#         nnkFormalParams.newTree(
#             newIdentNode("int"),
#             nnkIdentDefs.newTree(
#                 newIdentNode("this"),
#                 newIdentNode("Test2"),
#                 newEmptyNode()
#             ),
#             nnkIdentDefs.newTree(
#                 newIdentNode("value"),
#                 newIdentNode("int"),
#                 newEmptyNode()
#             )
#         ),
#         newEmptyNode(),
#         newEmptyNode(),
#         nnkStmtList.newTree(
#             nnkReturnStmt.newTree(
#                 newLit(0)
#             )
#         )
#     )


proc processSDKType(arg: NimNode, ast: NimNode): NimNode =
    # New procedures that will get created after the object definition.
    var generatedProcs: seq[NimNode] = @[]

    # echo "initial arg: ", arg.astGenRepr
    # echo "initial AST: ", ast.astGenRepr
    # echo "initial repr: ", ast.repr

    var newAst = ast.copy()

    var typeName: string
    var rawTypeName: string
    var typeNode = newAst[0][0]

    if typeNode[0].kind == nnkPragmaExpr:
        typeNode = typeNode[0]

    if typeNode[0].kind == nnkIdent:
        typeName = typeNode[0].strVal
        rawTypeName = typeName & "Raw"
        typeNode[0] = newIdentNode(rawTypeName)
    elif typeNode[0].kind == nnkPostfix:
        typeName = typeNode[0][1].strVal
        rawTypeName = typeName & "Raw"
        typeNode[0][1] = newIdentNode(rawTypeName)

    # echo "TYPE NAME IDENT: ", typeNameIdent.repr
    # If the user chose a name using the macro argument, use it here to override the default name.
    if arg.kind == nnkIdent:
        typeName = arg.strVal

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
                        let rawProcName = procName & "Raw"
                        let adjustedRawProcIdentDef = adjustRawProcIdentDef(identDef, rawProcName, procName)
                        # echo "--- adjusted def ast:\n", adjustedRawProcIdentDef.astGenRepr
                        # echo "--- adjusted def repr:\n", adjustedRawProcIdentDef.repr
                        recList[index] = adjustedRawProcIdentDef
                        let generatedProcDef = generateSDKProcDef(identDef, rawProcName, typeName, procName)
                        # echo "--- generated proc ast:\n", generatedProcDef.astGenRepr
                        # echo "--- generated proc repr:\n", generatedProcDef.repr
                        generatedProcs.add(generatedProcDef)
                    # For just importing the procedure, not used.
                    # elif idOrPragma[0].strVal == "importsdk" and identDef[1].kind == nnkProcTy:
                    #     echo "-- now importing the def: ", identDef.astGenRepr
                    #     var procName: string
                    #     let identProcName = identDef.findChild(it.kind == nnkPragmaExpr).findChild(it.kind == nnkIdent)
                    #     if identProcName != nil:
                    #         procName = identProcName.strVal
                    #     else:
                    #         procName = identDef.findChild(it.kind == nnkPragmaExpr)
                    #             .findChild(it.kind == nnkPostfix)[1].strVal
                    #     let rawProcName = procName
                    #     let adjustedRawProcIdentDef = adjustRawProcIdentDef(identDef, rawProcName, procName)
                    #     echo "--- adjusted def: ", adjustedRawProcIdentDef.astGenRepr
                    #     recList[index] = adjustedRawProcIdentDef
    
    let newTypeIdent = newIdentNode(typeName)
    let rawTypeIdent = newIdentNode(rawTypeName)
    let generatedNewType = quote do:
        type `newTypeIdent`* = ptr `rawTypeIdent`

    newAst.add(generatedNewType)

    for generatedProc in generatedProcs:
        newAst.add(generatedProc)

    result = newAst
    # echo "updated type AST: ", result.astGenRepr
    # echo "updated repr: ", result.repr

macro sdktype*(name: untyped, ast: untyped): untyped =
    return processSDKType(name, ast)


# dumpAstGen:
#     type TestSDK* = ptr Test2 

# sdktype TestSDK:
#     type Test2 {.importc: "const struct playdate_sys", header: "pd_api.h".} = object
#         obj: int
#         sdkObjProc {.importsdk.}: proc(v: cint, s: cstring): int
#         procNoSDK: proc(value: int)

# dumpAstGen:
#     type TestSDK* = ptr Test2 
#     type Test3* {.importc: "const struct playdate_sys", header: "pd_api.h".} = object
#         sdkObjProcRaw {.importc: "sdkObjProc".}: proc(v: cint, s: cstring) {.cdecl, raises: [].}
#         procNoSDK: proc(value: int)


# var test: TestSDK
# echo "THIS IS THE RETURN OF THE GENERATED PROC: ", test.sdkObjProc(0, "")
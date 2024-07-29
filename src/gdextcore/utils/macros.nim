import std/[ hashes, tables ]

import std/[ macros ]
export       macros

iterator breakArgs*(node: NimNode): tuple[index: int; def: tuple[name, Type, default: NimNode]] =
  node.expectKind nnkFormalParams
  var index: int
  for defs in node[1..^1]:
    for id in defs[0..^3]:
      yield (index, (id, defs[^2], defs[^1]))
      inc index

func hasNoReturn*(node: NimNode): bool =
  node.expectKind RoutineNodes
  node.params[0].kind == nnkEmpty or node.params[0].eqIdent("void")

func hasReturn*(node: NimNode): bool =
  not node.hasNoReturn

func hash*(node: NimNode): Hash = hash node.signatureHash

func typeDef*(typ: NimNode): NimNode =
  case typ.typeKind
  of ntyTypeDesc:
    let typ = typ.getTypeInst[1]
    case typ.kind
    of nnkBracketExpr:
      typ[0].getImpl
    else:
      typ.getImpl
  of ntyGenericInst:
    typ[0].getImpl
  else:
    error lisprepr typ, typ
    nil

func objectTy*(node: NimNode): NimNode =
  case node.kind
  of nnkTypeDef:
    node[2].objectTy
  of nnkRefTy, nnkPtrTy:
    node[0]
  of nnkObjectTy:
    node
  else:
    error lisprepr node, node
    nil

func ofInherit*(node: NimNode): NimNode =
  case node.kind
  of nnkObjectTy:
    node[1]
  of nnkOfInherit:
    node
  else:
    error lisprepr node, node
    nil

func typeSym*(node: NimNode): NimNode =
  case node.kind
  of nnkTypeDef:
    node[0]
  of nnkPragmaExpr:
    node[0].typeSym
  of nnkOfInherit:
    node[0]
  of nnkSym:
    node
  else:
    error lisprepr node, node
    nil

func recList*(node: NimNode): NimNode =
  case node.kind
  of nnkObjectTy:
    node[2]
  of nnkBracketExpr:
    node.typeDef.recList
  else:
    node.objectTy.recList

proc super*(typedes: NimNode): NimNode =
  var
    cache {.global.}: Table[NimNode, NimNode]
  let
    typedef = typedes.typeDef
    typesym = typedef.typeSym

  if typesym in cache:
    return cache[typesym]

  result = typedef.objectTy.ofInherit.typeSym
  cache[typesym] = result
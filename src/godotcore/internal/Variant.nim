import commandindex
import builtinindex

type
  Variant* {.byref.} = object
    data*: tuple[
      `type`: uint64,
      opaque: array[4, pointer],
    ]

proc `=copy`(dest: var Variant; source: Variant)
proc `=dup`(x: Variant): Variant
proc `=destroy`(x: Variant)

proc `=destroy`(x: Variant) =
  try:
    if x != Variant():
      interface_variantDestroy(addr x)
  except: discard
proc `=dup`(x: Variant): Variant =
  interface_variantNewCopy(addr result, addr x)
proc `=copy`(dest: var Variant; source: Variant) =
  `=destroy` dest
  wasMoved(dest)
  interface_variantNewCopy(addr dest, addr source)

import dirty/gdextension_interface
import commandindex

import std/macros
import std/hashes
import std/tables

type
  ObjectControlFlag* = enum
    OC_wasLocked

  ObjectControl* = object
    owner*: ObjectPtr
    flags*: set[ObjectControlFlag]

type
  GodotClass* = ref object of RootObj
    control: ObjectControl
  SomeClass* = GodotClass

  SomeEngineClass* = concept type t
    t is GodotClass
    t.EngineClass is t
  SomeUserClass* = concept type t
    t is GodotClass
    t.EngineClass isnot t

template CLASS_getObjectPtr*(class: GodotClass): ObjectPtr =
  if class.isNil: nil
  else: class.control.owner
template CLASS_getObjectPtrPtr*(class: GodotClass): ptr ObjectPtr =
  if class.isNil or class.control.owner.isNil: nil
  else: addr class.control.owner

template CLASS_lockDestroy(class: GodotClass) =
  class.control.flags.incl OC_wasLocked
  GC_ref class
template CLASS_unlockDestroy(class: GodotClass) =
  if OC_wasLocked in class.control.flags:
    GC_unref class
    class.control.flags.excl OC_wasLocked

template CLASS_create*[T: GodotClass](o: ObjectPtr): T =
  T(
    control: ObjectControl(
      owner: o
    )
  )

template CLASS_sync_create*(class: GodotClass) =
  CLASS_lockDestroy class
template CLASS_sync_free*(class: GodotClass) =
  CLASS_unlockDestroy class
template CLASS_sync_refer*(class: GodotClass; reference: bool): bool =
  true
template CLASS_sync_encode*(class: GodotClass) =
  discard
template CLASS_sync_decode*(class: GodotClass) =
  discard
template CLASS_sync_decode_result*(class: GodotClass) =
  discard


proc bind_virtuals*(_: typedesc[GodotClass]; T: typedesc) = discard

proc getInstance*[T: GodotClass](p_engine_object: ObjectPtr; _: typedesc[T]): T =
  if p_engine_object.isNil: return
  result = cast[T](interface_objectGetInstanceBinding(p_engine_object, environment.library, addr T.callbacks))

# User Class callbacks
# ====================
method notification*(self: GodotClass; p_what: int32) {.base.} = discard
method set*(self: GodotClass; p_name: ConstStringNamePtr; p_value: ConstVariantPtr): Bool {.base.} = discard
method get*(self: GodotClass; p_name: ConstStringNamePtr; r_ret: VariantPtr): Bool {.base.} = discard
method property_canRevert*(self: GodotClass; p_name: ConstStringNamePtr): Bool {.base.} = discard
method property_getRevert*(self: GodotClass; p_name: ConstStringNamePtr; r_ret: VariantPtr): Bool {.base.} = discard
method toString*(self: GodotClass; r_is_valid: ptr Bool; p_out: StringPtr) {.base.} = discard
method get_propertyList*(self: GodotClass; r_count: ptr uint32): ptr PropertyInfo {.base.} = r_count[] = 0
method free_propertyList*(self: GodotClass; p_list: ptr PropertyInfo) {.base.} = discard

{.experimental: "dynamicBindSym".}
proc hash(node: NimNode): Hash = hash node.signatureHash
macro Super*(Type: typedesc): typedesc =
  var cache {.global.}: Table[NimNode, NimNode]
  let typeSym = Type.getTypeImpl[1]

  try:
    result = cache[typesym]
    return

  except:
    # hint lisprepr typesym.getimpl
    let typeDef = typeSym.getImpl
    case typeDef.kind
    of nnkTypeDef:
      let typedefop = typedef[2]
      let objectty = case typedefop.kind
      of nnkRefTy:
        typedefop[0]
      of nnkDotExpr:
        typedefop.getTypeImpl[0].getImpl[2]
      else:
        error "Parse Error", Type
        nil

      let ofInherit = objectty[1]
      case ofInherit.kind
      of nnkOfInherit:
        cache[typeSym] = ofInherit[0]
        return ofInherit[0]

      of nnkEmpty:
        error "Type has no super object", Type
      else:
        error "Parse Error", Type

    of nnkNilLit:
      error "Type is not object.", Type
    else:
      error "Parse Error.", Type

import dirty/gdextensioninterface
import commandindex
import builtinindex
import extracommands

import utils/macros
import std/tables
import std/typetraits

const EnableDebugInterface {.booldefine.} = false

when EnableDebugInterface:
  type SYNC* = enum
    INSTANTIATE      = "SYNC--------INSTANTIATE: "
    CREATE_BIND      = "SYNC----CREATE(LIBRARY): "
    CREATE_CALL      = "SYNC----CREATE(BUILTIN): "
    FREE_BIND        = "SYNC------FREE(LIBRARY): "
    FREE_CALL        = "SYNC------FREE(BUILTIN): "
    REFERENCE        = "SYNC-REFERENCE(BUILTIN): "
    REFERENCE_BIND   = "SYNC----------REFERENCE: "
    UNREFERENCE_BIND = "SYNC----------REFERENCE: "
    ENCODE           = "SYNC-------------ENCODE: "
    DECODE           = "SYNC-------------DECODE: "
    DECODE_RESULT    = "SYNC-----DECODE(RESULT): "
    DESTROY          = "SYNC------------DESTROY: "

type
  ObjectControlFlag* = enum
    OC_godotManaged

  ObjectControl* = object
    owner*: ObjectPtr
    flags*: set[ObjectControlFlag]
    when EnableDebugInterface:
      name*: string

proc `=destroy`*(x: ObjectControl) =
  when EnableDebugInterface:
    echo SYNC.DESTROY, x.name
  if OC_godotManaged notin x.flags:
    destroy x.owner


type
  GodotClass* = ref object of RootObj
    control: ObjectControl
  GodotClassMeta* = ref object
    virtualMethods*: TableRef[StringName, ClassCallVirtual]
    className*: StringName
    callbacks*: InstanceBindingCallbacks

  SomeClass* = GodotClass
  SomeEngineClass* = concept type t
    t is GodotClass
    t.EngineClass is t
  SomeUserClass* = concept type t
    t is GodotClass
    t.EngineClass isnot t

template isRefCounted*(_: typedesc[GodotClass]): static bool = false

template CLASS_getObjectPtr*(class: GodotClass): ObjectPtr =
  if class.isNil: nil
  else: class.control.owner
template CLASS_getObjectPtrPtr*(class: GodotClass): ptr ObjectPtr =
  if class.isNil or class.control.owner.isNil: nil
  else: addr class.control.owner

template CLASS_passOwnershipToGodot*(class: GodotClass) =
  class.control.flags.incl OC_godotManaged
  GC_ref class
template CLASS_unlockDestroy(class: GodotClass) =
  if OC_godotManaged in class.control.flags:
    GC_unref class

method init*(self: GodotClass) {.base.}

template CLASS_create*[T: SomeClass](Type: typedesc[T]; o: ObjectPtr): Type =
  when EnableDebugInterface:
    var res = Type(
      control: ObjectControl(
        owner: o,
        name: $Type, ))
  else:
    var res = Type(
      control: ObjectControl(
        owner: o, ))
  init res
  res

template CLASS_sync_instantiate*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.INSTANTIATE, $typeof T

template CLASS_sync_create_bind*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.CREATE_BIND, $typeof T
  CLASS_passOwnershipToGodot class
template CLASS_sync_create_call*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.CREATE_CALL, $typeof T
  CLASS_passOwnershipToGodot class

template CLASS_sync_free_bind*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.FREE_BIND, $typeof T
  CLASS_unlockDestroy class
template CLASS_sync_free_call*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.FREE_CALL, $typeof T
  CLASS_unlockDestroy class

template CLASS_sync_refer*[T: SomeClass](class: T; reference: bool): bool =
  when EnableDebugInterface:
    let count = hook_getReferenceCount CLASS_getObjectPtr class
    echo SYNC.REFERENCE, $typeof T, "(", (if reference: $count.pred & " +1" else: $count.succ & " -1"), ")"
  true

template CLASS_sync_reference_bind*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    let count = hook_getReferenceCount CLASS_getObjectPtr class
    echo SYNC.REFERENCE_BIND, $typeof T, "(", $count.pred & " +1)"
template CLASS_sync_unreference_bind*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    let count = hook_getReferenceCount CLASS_getObjectPtr class
    echo SYNC.UNREFERENCE_BIND, $typeof T, "(", $count.succ & " -1)"

template CLASS_sync_encode*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.ENCODE, $typeof T
  discard
template CLASS_sync_decode*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.DECODE, $typeof T
  discard
template CLASS_sync_decode_result*[T: SomeClass](class: T) =
  when EnableDebugInterface:
    echo SYNC.DECODE_RESULT, $typeof T
  discard


var metaDB: Table[StringName, GodotClassMeta]
proc Meta*(T: typedesc[SomeClass]): GodotClassMeta =
  # The global specification to reference seems to be invalid and behaves the same
  # as a normal local variable. (It is immediately freed.)
  var dataptr {.global.} : pointer
  once:
    var data = GodotClassMeta(
      virtualMethods: new TableRef[StringName, ClassCallVirtual],
      className: stringName $T,
    )
    data.callbacks.reference_callback =
      when true:
        proc (p_token: pointer; p_binding: pointer; p_reference: Bool): Bool {.gdcall.} =
          CLASS_sync_refer cast[T](p_binding), p_reference

    data.callbacks.create_callback =
      when T is SomeEngineClass:
        proc (p_token: pointer; p_instance: pointer): pointer {.gdcall.} =
          let class = CLASS_create(T, cast[ObjectPtr](p_instance))
          CLASS_sync_create_call class
          result = cast[pointer](class)
      else:
        nil
    data.callbacks.free_callback =
      when T is SomeEngineClass:
        proc (p_token: pointer; p_instance: pointer; p_binding: pointer) {.gdcall.} =
          CLASS_sync_free_call cast[T](p_binding)
      else:
        nil

    metaDB[data.className] = data
    dataptr = cast[pointer](data)
  cast[GodotClassMeta](dataptr)

{.push, inline.}
proc className*(T: typedesc[SomeClass]): var StringName =
  Meta(T).className

proc callbacks*(T: typedesc[SomeClass]): var InstanceBindingCallbacks =
  Meta(T).callbacks

proc vmethods*(T: typedesc[SomeClass]): TableRef[StringName, ClassCallVirtual] =
  Meta(T).virtualMethods
{.pop.}

proc getInstance*[T: GodotClass](p_engine_object: ObjectPtr; _: typedesc[T]): T =
  if p_engine_object.isNil: return
  result = cast[T](interface_objectGetInstanceBinding(p_engine_object, environment.library, addr T.callbacks))

# User Class callbacks

method init*(self: GodotClass) {.base.} = discard
method notification*(self: GodotClass; p_what: int32) {.base.} = discard
method set*(self: GodotClass; p_name: ConstStringNamePtr; p_value: ConstVariantPtr): Bool {.base.} = discard
method get*(self: GodotClass; p_name: ConstStringNamePtr; r_ret: VariantPtr): Bool {.base.} = discard
method property_canRevert*(self: GodotClass; p_name: ConstStringNamePtr): Bool {.base.} = discard
method property_getRevert*(self: GodotClass; p_name: ConstStringNamePtr; r_ret: VariantPtr): Bool {.base.} = discard
method toString*(self: GodotClass; r_is_valid: ptr Bool; p_out: StringPtr) {.base.} = discard
method get_propertyList*(self: GodotClass; r_count: ptr uint32): ptr PropertyInfo {.base.} = r_count[] = 0
method free_propertyList*(self: GodotClass; p_list: ptr PropertyInfo) {.base.} = discard

macro Super*(Type: typedesc): typedesc = Type.super
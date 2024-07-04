import godotcore/internal/dirty/gdextension_interface
import godotcore/internal/builtinindex
import godotcore/internal/extracommands
import godotcore/internal/GodotClass

import std/tables

type
  GodotClassMeta* = ref object
    virtualMethods*: TableRef[StringName, ClassCallVirtual]
    className*: StringName
    callbacks*: InstanceBindingCallbacks

proc initialize(T: typedesc[SomeEngineClass]; userdata: GodotClassMeta) =
  userdata.callbacks.create_callback = proc (p_token: pointer; p_instance: pointer): pointer {.gdcall.} =
    let class = CLASS_create[T](cast[ObjectPtr](p_instance))
    CLASS_sync_create_call class
    result = cast[pointer](class)
  userdata.callbacks.free_callback = proc (p_token: pointer; p_instance: pointer; p_binding: pointer) {.gdcall.} =
    CLASS_sync_free_call cast[T](p_binding)

proc initialize(T: typedesc[SomeUserClass]; userdata: GodotClassMeta) =
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
    data.callbacks.reference_callback = proc (p_token: pointer; p_binding: pointer; p_reference: Bool): Bool {.gdcall.} =
      CLASS_sync_refer cast[T](p_binding), p_reference
    initialize(T, data)
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

proc notification_bind*(p_instance: ClassInstancePtr; p_what: int32) {.gdcall.} =
  cast[GodotClass](p_instance).notification(p_what)
proc set_bind*(p_instance: ClassInstancePtr; p_name: ConstStringNamePtr; p_value: ConstVariantPtr): Bool {.gdcall.} =
  cast[GodotClass](p_instance).set(p_name, p_value)
proc get_bind*(p_instance: ClassInstancePtr; p_name: ConstStringNamePtr; r_ret: VariantPtr): Bool {.gdcall.} =
  cast[GodotClass](p_instance).get(p_name, r_ret)
proc property_canRevert_bind*(p_instance: ClassInstancePtr; p_name: ConstStringNamePtr): Bool {.gdcall.} =
  cast[GodotClass](p_instance).property_canRevert(p_name)
proc property_getRevert_bind*(p_instance: ClassInstancePtr; p_name: ConstStringNamePtr; r_ret: VariantPtr): Bool {.gdcall.} =
  cast[GodotClass](p_instance).property_getRevert(p_name, r_ret)
proc toString_bind*(p_instance: ClassInstancePtr; r_is_valid: ptr Bool; p_out: StringPtr) {.gdcall.} =
  cast[GodotClass](p_instance).toString(r_is_valid, p_out)
proc get_propertyList_bind*(p_instance: ClassInstancePtr; r_count: ptr uint32): ptr PropertyInfo {.gdcall.} =
  cast[GodotClass](p_instance).get_propertyList(r_count)
proc free_propertyList_bind*(p_instance: ClassInstancePtr; p_list: ptr PropertyInfo) {.gdcall.} =
  cast[GodotClass](p_instance).free_propertyList(p_list)
import std/macros

import virtuals

import godotcore/internal/dirty/gdextension_interface
import godotcore/internal/commandindex
import godotcore/internal/builtinindex
import godotcore/internal/extracommands
import godotcore/internal/eventindex
import godotcore/internal/GodotClass
import godotcore/internal/GodotClassMeta
import godotcore/classtraits

proc create_bind(T: typedesc[SomeUserClass]): ObjectPtr =
  let class = instantiate T
  CLASS_sync_create class
  return CLASS_getObjectPtr class

proc free_bind[T: SomeUserClass](class: T) =
  CLASS_sync_free class

proc creationInfo(T: typedesc[SomeUserClass]; is_virtual, is_abstract: bool): ClassCreationInfo =
  ClassCreationInfo(
    is_virtual: is_virtual,
    is_abstract: is_abstract,
    set_func: set_bind,
    get_func: get_bind,
    get_property_list_func: get_property_list_bind,
    free_property_list_func: free_property_list_bind,
    property_can_revert_func: property_can_revert_bind,
    property_get_revert_func: property_get_revert_bind,
    notification_func: notification_bind,
    to_string_func: to_string_bind,
    create_instance_func: proc(p_userdata: pointer): ObjectPtr {.gdcall.} = T.create_bind(),
    free_instance_func: proc(p_userdata: pointer; p_instance: pointer) {.gdcall.} = cast[T](p_instance).free_bind(),
    get_virtual_func: get_virtual_bind,
    class_userdata: cast[pointer](Meta(T)),
  )

macro gdsync*(body): untyped =
  case body.kind
  of nnkMethodDef:
    sync_methodDef(body)
  else:
    body

proc register*(T: typedesc) =
  let info = T.creationInfo(false, false)
  interface_ClassDB_registerExtensionClass(environment.library, addr className(T), addr className(T.Super), addr info)
  invoke contract_method(T)
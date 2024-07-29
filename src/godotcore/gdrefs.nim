import godotcore/extracommands
import godotcore/gdclass

type
  SomeRefCounted* = concept type t
    t.isRefCounted == true

  GdRef*[RefCounted: SomeRefCounted] = object
    handle*: RefCounted

proc `=destroy`*[T: SomeRefCounted](self: GdRef[T]) =
  if self.handle.isNil: return
  let objectptr = CLASS_getObjectPtr self.handle
  if hook_unreference(objectptr):
    destroy(objectptr)
proc `=copy`*[T: SomeRefCounted](dst: var GdRef[T]; src: GdRef[T]) =
  `=destroy` dst
  wasMoved dst
  dst.handle = src.handle
  discard hook_reference(CLASS_getObjectPtr dst.handle)
proc `=dup`*[T: SomeRefCounted](src: GdRef[T]): GdRef[T] =
  result.handle = src.handle
  discard hook_reference(CLASS_getObjectPtr result.handle)


proc unwrapped*[T: SomeRefCounted](self: GdRef[T]): T = self.handle

template gdref*[T: SomeRefCounted](Type: typedesc[T]): typedesc = GdRef[Type]
proc referenced*[T: SomeRefCounted](self: T): GdRef[T] =
  result.handle = self
  discard hook_reference(CLASS_getObjectPtr self)
proc asGdRef*[T: SomeRefCounted](self: T): GdRef[T] =
  result.handle = self
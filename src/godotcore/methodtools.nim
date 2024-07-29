import dirty/gdextensioninterface
import gdvariant
import gdclass
import gdrefs

export gdcall

template CLASS_getOwner*(v: GodotClass): ObjectPtr =
  CLASS_getObjectPtr v

template getPtr*[T](v: T): pointer = cast[pointer](addr v)
template getPtr*(v: Variant): pointer = cast[pointer](addr v.data)
template getPtr*[T: GodotClass](v: T): pointer =
  if v.isNil: nil
  else:
    CLASS_sync_encode v
    cast[pointer](CLASS_getObjectPtrPtr v)
template getPtr*(v: GdRef): pointer =
  getPtr v.handle

template getTypedPtr*(v: Variant): VariantPtr = addr v
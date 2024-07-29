import dirty/gdextensioninterface
import config
import geometrics
import commandindex

when DecimalPrecision == "double":
  type real_elem* = float64
elif DecimalPrecision == "float" or true:
  type real_elem* = float32

type int_elem* = int32
type float_elem* = float32

type Opaque[I: static int] = array[I, pointer]

type
  VectorR*[N: static int] = Vector[N, real_elem]
  VectorI*[N: static int] = Vector[N, int_elem]

export Bool
export Int
type
  Float* = float64
  Vector2* = VectorR[2]
  Vector3* = VectorR[3]
  Vector4* = VectorR[4]
  Vector2i* = VectorI[2]
  Vector3i* = VectorI[3]
  Vector4i* = VectorI[4]
  Rect2* {.byref.} = object
    position*: Vector2
    size*: Vector2
  Rect2i* {.byref.} = object
    position*: Vector2i
    size*: Vector2i
  Transform2D* {.byref.} = object
    x*: Vector2
    y*: Vector2
    origin*: Vector2
  Plane* {.byref.} = object
    normal*: Vector3
    d*: real_elem
  Quaternion* {.byref.} = object
    x*: real_elem
    y*: real_elem
    z*: real_elem
    w*: real_elem
  AABB* {.byref.} = object
    position*: Vector3
    size*: Vector3
  Basis* {.byref.} = object
    x*: Vector3
    y*: Vector3
    z*: Vector3
  Transform3D* {.byref.} = object
    basis*: Basis
    origin*: Vector3
  Projection* {.byref.} = object
    x*: Vector4
    y*: Vector4
    z*: Vector4
    w*: Vector4
  Color* {.byref.} = object
    r*: float_elem
    g*: float_elem
    b*: float_elem
    a*: float_elem
  RID* {.bycopy.} = object
    opaque: Opaque[2]
  String* {.bycopy.} = object
    opaque: Opaque[1]
  StringName* {.bycopy.} = object
    opaque: Opaque[1]
  NodePath* {.bycopy.} = object
    opaque: Opaque[1]
  Callable* {.bycopy.} = object
    opaque: Opaque[4]
  Signal* {.bycopy.} = object
    opaque: Opaque[4]
  Dictionary* {.bycopy.} = object
    opaque: Opaque[1]
  Array* {.bycopy.} = object
    opaque: Opaque[1]
  PackedByteArray* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[byte]
  PackedInt32Array* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[int32]
  PackedInt64Array* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[int64]
  PackedFloat32Array* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[float32]
  PackedFloat64Array* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[float64]
  PackedStringArray* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[String]
  PackedVector2Array* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[Vector2]
  PackedVector3Array* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[Vector3]
  PackedColorArray* {.bycopy.} = object
    proxy: pointer
    data_unsafe*: ptr UncheckedArray[Color]


type SomePackedArray* =
  PackedByteArray    |
  PackedInt32Array   |
  PackedInt64Array   |
  PackedFloat32Array |
  PackedFloat64Array |
  PackedStringArray  |
  PackedVector2Array |
  PackedVector3Array |
  PackedColorArray
type SomeFloatVector* =
  Vector2 |
  Vector3 |
  Vector4
type SomeIntVector* =
  Vector2i |
  Vector3i |
  Vector4i
type SomeVector* =
  SomeFloatVector |
  SomeIntVector
type SomePrimitives* =
  Bool         |
  Int          |
  Float        |
  SomeVector   |
  Rect2        |
  Rect2i       |
  Transform2D  |
  Plane        |
  Quaternion   |
  AABB         |
  Basis        |
  Transform3D  |
  Projection   |
  Color
type SomeGodotUniques* =
  String          |
  StringName      |
  NodePath        |
  RID             |
  Callable        |
  Signal          |
  Dictionary      |
  Array           |
  SomePackedArray
type SomeBuiltins* = SomePrimitives|SomeGodotUniques

include "builtinindex/hookprototype"
include "builtinindex/hookdefine"

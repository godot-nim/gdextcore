import godotcore/dirty/gdextension_interface; export gdextension_interface
import godotcore/builtinindex; export builtinindex
import godotcore/commandindex; export commandindex
import godotcore/methodtools; export methodtools
import godotcore/typeshift; export typeshift
import godotcore/GodotClass; export GodotClass
import godotcore/Variant; export Variant
import godotcore/TypedArray; export TypedArray
import godotcore/extracommands; export gdstring, stringname, classname

import std/tables; export Table, toTable, initTable

proc concat*[T,S](a, b: Table[T,S]): Table[T,S] =
  result = a
  for key, value in b.pairs:
    result[key] = value

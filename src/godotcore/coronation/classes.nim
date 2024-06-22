import godotcore/internal/dirty/gdextension_interface; export gdextension_interface
import godotcore/internal/builtinindex; export builtinindex
import godotcore/internal/commandindex; export commandindex
import godotcore/internal/methodtools; export methodtools
import godotcore/internal/typeshift; export typeshift
import godotcore/internal/GodotClassMeta; export GodotClassMeta
import godotcore/internal/Variant; export Variant
import godotcore/internal/TypedArray; export TypedArray
import godotcore/internal/extracommands; export gdstring, stringname, classname

import std/tables; export Table, toTable, initTable

proc concat*[T,S](a, b: Table[T,S]): Table[T,S] =
  result = a
  for key, value in b.pairs:
    result[key] = value

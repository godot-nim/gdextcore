import godotcore/dirty/gdextensioninterface; export gdextensioninterface
import godotcore/builtinindex; export builtinindex
import godotcore/commandindex; export commandindex
import godotcore/methodtools; export methodtools
import godotcore/typeshift; export typeshift
import godotcore/gdclass; export gdclass
import godotcore/gdvariant; export gdvariant
import godotcore/gdtypedarray; export gdtypedarray
import godotcore/gdrefs; export gdrefs
import godotcore/extracommands; export gdstring, stringname, classname

import std/tables; export Table, toTable, initTable

proc concat*[T,S](a, b: Table[T,S]): Table[T,S] =
  result = a
  for key, value in b.pairs:
    result[key] = value

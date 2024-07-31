import gdextcore/dirty/gdextensioninterface; export gdextensioninterface
import gdextcore/builtinindex; export builtinindex
import gdextcore/commandindex; export commandindex
import gdextcore/methodtools; export methodtools
import gdextcore/typeshift; export typeshift
import gdextcore/gdclass; export gdclass
import gdextcore/gdvariant; export gdvariant
import gdextcore/gdtypedarray; export gdtypedarray
import gdextcore/gdrefs; export gdrefs
import gdextcore/extracommands; export gdstring, stringname, classname
import gdextcore/exceptions; export exceptions

import std/tables; export Table, toTable, initTable

proc concat*[T,S](a, b: Table[T,S]): Table[T,S] =
  result = a
  for key, value in b.pairs:
    result[key] = value

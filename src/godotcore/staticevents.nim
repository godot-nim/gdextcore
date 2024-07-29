import std/macros
import std/tables
import std/hashes

# const EnableDebugEvent {.booldefine.} = false

type Event = distinct string
proc event*(name: string): Event = Event name
proc hash*(event: Event): Hash {.borrow.}
proc `==`*(a, b: Event): bool {.borrow.}

type ProcessBody = NimNode
var eventtable {.compileTime.} : Table[Event, seq[ProcessBody]]

macro invoke*(event: static Event): untyped =
  if not eventtable.hasKey(event): return

  let eventhandler = ident (string event) & "_handle"

  let eventproc = newProc(name = eventhandler,  body = newStmtList())

  for process in eventtable[event]:
    case process.kind
    of nnkStmtList:
      eventproc.body.add newBlockStmt(process)
    else:
      eventproc.body.add newBlockStmt(process)

  result = quote do:
    `eventproc`
    `eventhandler`()

macro process*(event: static Event; body) =
  if eventtable.hasKey(event):
    eventtable[event].add body
  else:
    eventtable[event] = @[body]

macro process*(event: static Event; name: string; body) =
  if eventtable.hasKey(event):
    eventtable[event].add body
  else:
    eventtable[event] = @[body]

const init_engine* = (
    on_load_builtinclassConstructor: event("load_builtinclassConstructor"),
    on_load_builtinclassOperator: event("load_builtinclassOperator"),
    on_load_builtinclassMethod: event("load_builtinclassMethod"),
)
import std/macros
import std/tables
import std/hashes

# const EnableDebugEvent {.booldefine.} = false

type Event* = distinct string
proc event*(name: string): Event = Event name
proc hash*(event: Event): Hash {.borrow.}
proc `==`*(a, b: Event): bool {.borrow.}

type ProcessBody = NimNode
var eventtable {.compileTime.} : Table[Event, tuple[consumed: bool, list: seq[ProcessBody]]]

macro invoke*(event: static Event): untyped =
  if eventtable.hasKey(event):
    eventtable[event].consumed = true
  else:
    eventtable[event] = (true, @[])
    return

  let eventhandler = ident (string event) & "_handle"

  let eventproc = newProc(name = eventhandler,  body = newStmtList())

  for process in eventtable[event].list:
    case process.kind
    of nnkStmtList:
      eventproc.body.add newCall(process)
    else:
      eventproc.body.add newCall(process)

  result = quote do:
    `eventproc`
    `eventhandler`()

macro process*(event: static Event; body): untyped =
  let name = gensym(nskProc)
  result = newProc(name, body= body)

  if eventtable.hasKey(event):
    if eventtable[event].consumed:
      error "the event " & event.string & " is already consumed", body
    eventtable[event].list.add name
  else:
    eventtable[event] = (false, @[name])

macro process*(event: static Event; name: string; body) =
  let name = gensym(nskProc)
  result = newProc(name, body= body)

  if eventtable.hasKey(event):
    if eventtable[event].consumed:
      error "the event " & event.string & " is already consumed", body
    eventtable[event].list.add name
  else:
    eventtable[event] = (false, @[name])

const init_engine* = (
    on_load_builtinclassConstructor: event("load_builtinclassConstructor"),
    on_load_builtinclassOperator: event("load_builtinclassOperator"),
    on_load_builtinclassMethod: event("load_builtinclassMethod"),
)
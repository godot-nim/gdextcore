type
  EventState* = enum
    Ready, Processing, Completed
  Event* = ref object
    state*: EventState
    requires: seq[Event]
    data: tuple[
      process: seq[proc()],
      name_process: seq[string],
    ]

    name*: string

proc event*(name: string): Event = Event(name: name)

proc invoke*(event: Event) =
  if event.state > Ready: return
  event.state = Processing
  defer:
    event.state = Completed
    event.data.process.setLen(0)
    event.data.name_process.setLen(0)

  for require in event.requires:
    echo event.name, "::invoke>> ", require.name, "..."
    invoke require

  for i, callback in event.data.process:
    echo event.name, "::process>> ", event.data.name_process[i], "..."
    callback()

proc isCompleted*(event: Event): bool = event.state == Completed

proc require*(event, target: Event) =
  if event.state > Ready:
    echo event.name, "::invoke>> ", target.name, "..."
    invoke target
    return
  event.requires.add target

proc register_process*(event: Event; name: string; callback: proc()) =
  if event.state > Ready:
    echo event.name, "::process>> ", name, "..."
    callback()
    return
  event.data.name_process.add name
  event.data.process.add callback

template process*(event: Event; body): untyped =
  event.register_process "process #" & $event.data.process.len,  proc() =
    body

template process*(event: Event; name: string; body): untyped =
  event.register_process name, proc() =
    body

var init_engine* = (
    on_load_builtinclassConstructor: event("load_builtinclassConstructor"),
    on_load_builtinclassOperator: event("load_builtinclassOperator"),
    on_load_builtinclassMethod: event("load_builtinclassMethod"),
    on_load_metadata: event("load_metadata"),
)

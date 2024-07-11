import std/unittest
import godotcore/events

suite "Event":
  test "test":
    var result: seq[string]

    let A = event("A")
    let B = event("B")
    let C = event("C")
    let D = event("D")
    let E = event("E")

    C.require B
    C.require A
    B.require A

    process A: result.add "A"
    process B: result.add "B"
    process C: result.add "C"

    C.require D

    process D: B.require E
    process D: result.add "D"

    process E: result.add "E"


    invoke C
    echo result
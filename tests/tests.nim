import unittest
import events

test "events":
  var e: Event[int]
  var eh: EventHandler
  var capture = 0

  e.emit 1
  check capture == 0

  e.connect eh, proc(v: int) =
    capture = v

  e.emit 2
  check capture == 2
  e.emit 3
  check capture == 3

  e.disconnect eh

  e.emit 4
  check capture == 3

  (proc =
    var eh2: EventHandler
    e.connect eh2, proc(v: int) =
      capture = v
    e.emit 5
    check capture == 5
  )()
  
  e.emit 6
  when defined(orc) or defined(arc):
    check capture == 5
  else:
    ## don't check, garbadge collection is unpredictable


type  
  EventHandler* = object  # pointer is wrapped to an object to attach custom destructor
    p: ptr EventHandlerObj

  EventHandlerObj = object
    connected: seq[ptr EventBase]


  EventConnection[T] = tuple
    eh: ptr EventHandlerObj
    f: proc(v: T) {.closure.}


  EventBase = object
    connected: seq[EventConnection[int]]  # type of function argument does not matter for this


  Event*[T] = object  # pointer is wrapped to an object to attach custom destructor
    ## only EventHandler can be connected to Event
    ## one event can be connected to multiple handlers
    ## one event handler can connect to multiple events
    ## one event can be connected to one event handler multiple times
    ## connection can be removed, but if EventHandler connected to Event multiple times, they all will be removed
    p: ptr EventObj[T]

  EventObj[T] = object
    connected: seq[EventConnection[T]]



proc destroyEvent(s: ptr EventBase) {.raises: [].}
proc destroyEventHandler(handler: ptr EventHandlerObj) {.raises: [].}


proc `=destroy`[T](s: Event[T]) =
  if s.p != nil:
    destroyEvent(cast[ptr EventBase](s.p))

proc `=destroy`(s: EventHandler) =
  if s.p != nil:
    destroyEventHandler(s.p)


proc initIfNeeded[T](s: var Event[T]) =
  if s.p == nil:
    s.p = cast[ptr EventObj[T]](alloc0(sizeof(EventObj[T])))

proc initIfNeeded(s: var EventHandler) =
  if s.p == nil:
    s.p = cast[ptr EventHandlerObj](alloc0(sizeof(EventHandlerObj)))


proc destroyEvent(s: ptr EventBase) =
  for (handler, _) in s[].connected:
    var i = 0
    while i < handler[].connected.len:
      if handler[].connected[i] == s:
        handler[].connected.del i
      else:
        inc i
  dealloc s

proc destroyEventHandler(handler: ptr EventHandlerObj) =
  for s in handler[].connected:
    var i = 0
    while i < s[].connected.len:
      if s[].connected[i][0] == handler:
        s[].connected.del i
      else:
        inc i
  dealloc handler


proc disconnect*[T](x: var Event[T]) =
  if x.p == nil: return
  destroyEvent cast[ptr EventBase](x.p)
  x.p = nil

proc disconnect*(x: var EventHandler) =
  if x.p == nil: return
  destroyEventHandler x.p
  x.p = nil


proc disconnect*[T](s: var Event[T], c: var EventHandler) =
  if s.p == nil or c.p == nil: return
  var i = 0
  while i < c.p[].connected.len:
    if c.p[].connected[i] == cast[ptr EventBase](s.p):
      c.p[].connected.del i
    else:
      inc i
  
  i = 0
  while i < s.p[].connected.len:
    if s.p[].connected[i].eh == c.p:
      s.p[].connected.del i
    else:
      inc i


proc emit*[T](s: Event[T], v: T) =
  if s.p == nil: return
  var i = 0
  while i < s.p[].connected.len:
    s.p[].connected[i].f(v)
    inc i

proc emit*(s: Event[void]) =
  if s.p == nil: return
  var i = 0
  while i < s.p[].connected.len:
    s.p[].connected[i].f()
    inc i


proc connect*[T](s: var Event[T], c: var EventHandler, f: proc(v: T)) =
  initIfNeeded s
  initIfNeeded c
  s.p[].connected.add (c.p, f)
  c.p[].connected.add cast[ptr EventBase](s.p)

proc connect*(s: var Event[void], c: var EventHandler, f: proc()) =
  initIfNeeded s
  initIfNeeded c
  s.p[].connected.add (c.p, f)
  c.p[].connected.add cast[ptr EventBase](s.p)


template connectTo*[T](s: var Event[T], obj: var EventHandler, body: untyped) =
  connect s, obj, proc(e {.inject.}: T) =
    body

template connectTo*(s: var Event[void], obj: var EventHandler, body: untyped) =
  connect s, obj, proc() =
    body

template connectTo*[T](s: var Event[T], obj: var EventHandler, argname: untyped, body: untyped) =
  connect s, obj, proc(argname {.inject.}: T) =
    body

template connectTo*(s: var Event[void], obj: var EventHandler, argname: untyped, body: untyped) =
  connect s, obj, proc() =
    body


proc hasHandlers*(e: Event): bool =
  if e.p == nil: return false
  e.p.connected.len > 0

# Events
<img alt="events" width="100%" src="http://levovix.ru:8000/docs/events/banner.png">
<p align="center">
  React to events happened in unrelated parts of program
</p>

```nim
var event: Event[int]
var eventHandler: EventHandler

event.connect eventHandler, proc(e: int) =
  echo e

event.connectTo eventHandler, val:
  echo "another ", val

event.emit(10)
# 10
# another 10
```

Events (of any type) can be connected to EventHandler object.

You can check `event.hasHandlers` for optimizing if you need to do complex logic to emit event. *Don't do work if no one notice.*


# Installation

To install system-wide
```sh
nimble install https://github.com/levovix/events
```

To require in other package
```nim
requires "https://github.com/levovix/events >= 0.1"
```


# Disconnecting

```nim
disconnect event, eventHandler
disconnect eventHandler  # disconnects all events
disconnect event  # disconnects all event handlers
```

Event and EventHandler contains weak references to each other, they automatically disconnects on destruction.

```nim
type
  Player = ref object
    # ...
    moved: Event[void]

  Enemy = ref object
    # ...
    eh: EventHandler

proc onCreated(enemy: Enemy, world: World) =
  let player = world.getPlayer()
  player.moved.connectTo enemy.eh:
    enemy.lookAt player.pos

proc on_w_key_pressed(player: Player) =
  player.y -= 1
  player.moved.emit()
```


# TODO
- [ ] Check memory management in clojures (is it leak-safe?)

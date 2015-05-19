# Easy undo in Elm with elm-undo-redo

This package makes dealing with undo extremely easy in Elm. By enforcing immutability, Elm applications
have the benefit that, at any given time, the entire state of the application is known. Therefore, theoretically
undo is trivial as one merely needs to capture the past states and then move back one state in the past. This is
exactly what this library does. Furthermore, by embracing functional programming an a clear and simple functional
reactive model, it is possible to provide abstractions to support undo/redo in absolutely any Elm application.


### How it works

The library is centered around a single data structure, the `UndoList`.

```elm
type alias UndoList state =
  { past    : List state
  , present : state
  , future  : List state
  }
```

An `UndoList` contains a list of past state, a present state, and a list of future states where the head of
the past list is the previous state and the head of the future list is the next state.

So, say you have a function to view a given state

```elm
view : state -> Html
```

You can use this function on an `UndoList` by extracting the present value (for example with the present function)

```elm
view (present states)

-- where states : UndoList state
-- given present : UndoList state -> state
```

If you wish to undo, it is as simple as calling the `undo` function on the `UndoList`

```elm
view (present (undo states))

-- undo : UndoList state -> UndoList state
```

Furthermore, given the simplicity of the `UndoList` data structure, the `undo` function has a trivial
implementation.

```elm
undo : UndoList state -> UndoList state
undo {past, present, future} =
  case past of
    [] ->
      UndoList past present future
    previous :: pastStates ->
      UndoList pastStates previous (present :: future)
```

All you need to do is set the previous state as the present state and add the old present state to the list of
future states.

Redo is defined just as trivially.

### How do you use it

Suppose you have this very simple counter application.

```elm
import Html
import Html.Events exposing (onClick)
import Signal exposing (mailbox)

initial = 0

update _ state = state + 1

view address state =
  Html.div
      []
      [ Html.button
            [ onClick address () ]
            [ Html.text "Increment" ]
      , Html.div
            []
            [ Html.text (toString state) ]
      ]

{address, signal} = mailbox ()

main =
  Signal.map (view address)
    (Signal.foldp update initial signal)
```

Where you have a button that, when clicked, increments a counter.

If we consider the [Elm Architecture](https://github.com/evancz/elm-architecture-tutorial), then this application
adheres to it with the following form:

```elm
initial : Int

update : () -> Int -> Int

view : Address () -> Int -> Html

address : Address ()

signal : Signal ()

main : Signal Html
main =
  Signal.map (view address)
    (Signal.foldp update initial signal)
```


Now, suppose that we wish to add a button that performs undo. To support this feature we need to :

**1) Import UndoList**

```elm
import Html
import Html.Events exposing (onClick)
import Signal exposing (mailbox)
import UndoList exposing (UndoList, Action(..), fresh, apply)
```

**2) Convert the initial model from `Int` to `UndoList Int`**

```elm
initial : UndoList Int
initial = fresh 0

-- fresh : a -> UndoList a
-- fresh creates an undo list with neither past nor future states
```

**3) Send undo list actions as opposed to simply `()` and add the undo button**

```elm
-- make sure you extract the present state
view : Address (Action ()) -> UndoList Int -> Html
view address {present} =
  Html.div
      []
      [ Html.button
            [ onClick address (New ()) ]
            [ Html.text "Increment" ]
      , Html.button
            [ onClick address Undo ]
            [ Html.text "Undo" ]
      , Html.div
            []
            [ Html.text (toString present) ]
      ]
```

`elm-redo-undo` provides a default `Action` type to wrap all your actions. It is defined as follows:

```elm
type Action a
  = Reset       -- reset the state to the oldest state, removing all other states
  | Undo        -- go back to the previous state (this is a no-op if there is no such state)
  | Redo        -- go to the next state (this is a no-op if there is no such state)
  | Forget      -- remove all past states
  | New a       -- add a new value or action. This removes all future states
```

If we simply wrap all actions send to the address with `New`, your application will be unchanged and will
just accumulate the past states without influencing the correctness of your code.


**4) Modify the mailbox to support undo list actions**

```elm
{address, signal} = mailbox Reset

-- address : Address (Action ())
-- signal : Signal (Action ())
```

Reset is harmless choice for an initial `Action` because it is a no-op on a fresh undo list.


**5) Apply the `update` function**

```elm
main : Signal Html
main =
  Signal.map (view address)
    (Signal.foldp (apply update) initial signal)
```

`apply` converts a function that updates a `state` given some `action` into a function that updates an
`UndoList state` given some `Action action`.

```elm
apply :  (action -> state -> state)
      -> (Action action -> UndoList state -> UndoList state)
```

**6) That's it!**

You're done. Seriously. You've just added undo to this counter without manually dealing with the undo logic.


Here's the whole code to convince yourself of this:

```elm
import Html
import Html.Events exposing (onClick)
import Signal exposing (mailbox)
import UndoList exposing (UndoList, Action(..), fresh, apply)

initial = fresh 0

update _ state = state + 1

view address {present} =
  Html.div
      []
      [ Html.button
            [ onClick address (New ()) ]
            [ Html.text "Increment" ]
      , Html.button
            [ onClick address Undo ]
            [ Html.text "Undo" ]
      , Html.div
            []
            [ Html.text (toString present) ]
      ]

{address, signal} = mailbox Reset

main =
  Signal.map (view address)
    (Signal.foldp (apply update) initial signal)
```

The best thing about this approach is that it is very general. The `update` function did not have to change
at all, and the `view` function only required minimal changes.

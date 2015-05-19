# Undo in any Elm app
     
> add undo/redo to any Elm application

Trying to add undo/redo in JS can be a nightmare. If anything gets mutated in an unexpected way, your history can get corrupted. Elm is built from the ground up around efficient, immutable data structures. That means adding support for undo/redo is a matter of remembering the state of your app at certain times. Since there is no mutation, there is no risk of things getting corrupted. Since immutability lets you do structural sharing within data structures, it also means these snapshots can be quite compact.

So this package takes these underlying strengths of Elm and turns them into a small package that lets you drop in undo/redo functionality in just a few lines of code!


### How it works

The library is centered around a single data structure, the `UndoList`.

```elm
type UndoList state = UndoList (List state) state (List state)
```

An `UndoList` contains a list of past state, a present state, and a list of future states where the head of 
the past list is the previous state and the head of the future list is the next state.

```elm
UndoList past present future
```

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
undo (UndoList past present future) = 
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
import UndoList exposing (UndoList(..), Action(..), fresh, apply)
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
-- make sure you extract the present state somehow
-- as you are passed the entire undo list
view : Address (Action ()) -> UndoList Int -> Html
view address (UndoList _ state _ ) = 
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
            [ Html.text (toString state) ] 
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
import UndoList exposing (UndoList(..), Action(..), fresh, apply)

initial = fresh 0

update _ state = state + 1

view address (UndoList _ state _ ) = 
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
            [ Html.text (toString state) ] 
      ]
      
{address, signal} = mailbox Reset

main = 
  Signal.map (view address)
    (Signal.foldp (apply update) initial signal)
```

The best thing about this appraoch is that it is very general. The `update` function did not have to change
at all, and the `view` function only required minimal changes. 

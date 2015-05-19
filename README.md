# Undo in any Elm app
     
> add undo/redo to any Elm application

Trying to add undo/redo in JS can be a nightmare. If anything gets mutated in an unexpected way, your history can get corrupted. Elm is built from the ground up around efficient, immutable data structures. That means adding support for undo/redo is a matter of remembering the state of your app at certain times. Since there is no mutation, there is no risk of things getting corrupted. Since immutability lets you do structural sharing within data structures, it also means these snapshots can be quite compact.

So this package takes these underlying strengths of Elm and turns them into a small package that lets you drop in undo/redo functionality in just a few lines of code!


## How it works

The library is centered around a single data structure, the `UndoList`.

```elm
type UndoList state =
    UndoList (List state) state (List state)
```

An `UndoList` contains a list of past state, a present state, and a list of future states. Since it keeps track of the past, present, and future, undo and redo are just a matter of sliding the present around a bit.


## Example

We will start with a very simple counter application. There is a button, and when it is clicked, it increments a counter.

```elm
import Html
import Html.Events exposing (onClick)
import Signal


initialModel =
  0

update _ model =
  model + 1

view address model = 
  Html.div 
      []
      [ Html.button 
          [ onClick address () ]
          [ Html.text "Increment" ]
      , Html.div 
          []
          [ Html.text (toString model) ]
      ]

actions =
  Signal.mailbox ()

main = 
  Signal.map (view actions.address)
    (Signal.foldp update initialModel actions.signal)
```

After we write that up, we decide it would be nice to have an undo button. The next code block is the same program updated to use the `UndoList` module to add this functionality. It is in one big block because it is mostly the same as the original, and we will go into the differences afterwards.

```elm
import Html
import Html.Events exposing (onClick)
import Signal
import UndoList

initialModel =
  UndoList.fresh 0

update _ state =
  state + 1

view address (UndoList _ state _ ) = 
  Html.div 
      []
      [ Html.button 
          [ onClick address (UndoList.New ()) ]
          [ Html.text "Increment" ]
      , Html.button 
          [ onClick address UndoList.Undo ]
          [ Html.text "Undo" ]
      , Html.div 
          []
          [ Html.text (toString state) ] 
      ]
      
actions =
  Signal.mailbox UndoList.Reset

main = 
  Signal.map (view actions.address)
    (Signal.foldp (UndoList.apply update) initialModel actions.signal)
```

The code looks pretty much the same, but we added a few things.

  1. We import the `UndoList` module.
  2. Our `initialModel` is now instantiated as a `fresh` `UndoList` which means we set the present value, but the past and future are totally blank.
  3. The `view` grabs the present value from the `UndoList`
  4. We added a new button to `view` that reports an `Undo` action.
  5. We use `UndoList.apply` in the `foldp` to handle any undo/redo stuff

To summarize this in a less technical way. We said we want to keep track of history, we added a button that describes how to move through history, and we added one function call that makes this all work together. Three little changes!

The crazy thing is that this same pattern will work no matter how large your app gets. You do not have to think about any nasty details of undo/redo, you make a tiny number of additions and the vast majority of the code stays exactly the same!


## More Details

This API is designed to work really nicely with [The Elm Architecture][arch], so it exposes an `Action` type that can easily be added to your existing ones:

[arch]: https://github.com/evancz/elm-architecture-tutorial/

```elm
type Action subaction
    = Reset
    | Redo
    | Undo
    | Forget
    | New subaction
```

You can specify all the normal actions of your application with `New` but you now have `Undo`, `Redo`, etc.

This becomes really powerful when paired with `apply` which handles all of the `UndoList` actions seamlessly.

```elm
apply
  : (action -> model -> model)
  -> (Action action -> UndoList model -> UndoList model)
```

It lets you write a normal `update` function and then upgrade it to a function that works on `UndoLists`.

The API has a lot more cool stuff, so [check it out][docs].

[docs]: http://package.elm-lang.org/packages/TheSeamau5/elm-undo-redo/latest

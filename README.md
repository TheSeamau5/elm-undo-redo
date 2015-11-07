# Undo in any Elm app

Add undo/redo to any Elm app with just a few lines of code!

Trying to add undo/redo in JS can be a nightmare. If anything gets mutated in an unexpected way, your history can get corrupted. Elm is built from the ground up around efficient, immutable data structures. That means adding support for undo/redo is a matter of remembering the state of your app at certain times. Since there is no mutation, there is no risk of things getting corrupted. Given immutability lets you do structural sharing within data structures, it also means these snapshots can be quite compact!


## How it works

The library is centered around a single data structure, the `UndoList`.

```elm
type alias UndoList state =
  { past    : List state
  , present : state
  , future  : List state
  }
```

An `UndoList` contains a list of past states, a present state, and a list of future states. By keeping track of the past, present, and future states, undo and redo become just a matter of sliding the present around a bit.


## Example

We will start with a very simple counter application. There is a button, and when it is clicked, a counter is incremented.

```elm
-- BEFORE
import Html
import Html.Events exposing (onClick)
import StartApp

main =
  StartApp.start
    { model = 0, view = view, update = update }

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
```

Suppose that further down the line we decide it would be nice to have an undo button.

The next code block is the same program updated to use the `UndoList` module to add this functionality. It is in one big block because it is mostly the same as the original, and we will go into the differences afterwards.

```elm
-- AFTER
import Html
import Html.Events exposing (onClick)
import StartApp
import UndoList as UL

main =
  StartApp.start
    { model = UL.fresh 0, view = UL.view view, update = UL.update update }

update _ model =
  model + 1

view address model =
  Html.div
      []
      [ Html.button
          [ onClick address (UL.New ()) ]
          [ Html.text "Increment" ]
      , Html.button
          [ onClick address UL.Undo ]
          [ Html.text "Undo" ]
      , Html.div
          []
          [ Html.text (toString model) ]
      ]
```

The code is almost *exactly* the same!

When we start the app, we simply add a couple wrappers to handle all of the undo/redo functionality. Notice that the addition of the functions `UL.fresh`, `UL.view`, and `UL.update` is a totally mechanical augmentation.

As for the actual code, we added another button to our view that reports an `Undo` action and we wrapped up the increment event with `New`. In other words, the bare essentials needed to describe the user facing functionality.

The crazy thing is that this same pattern will work no matter how large your app gets. You do not have to think about any nasty details of undo/redo. Just make a tiny number of additions and the vast majority of the code stays exactly the same!


## More Details

This API is designed to work really nicely with [The Elm Architecture][arch] by exposing an `Action` type that can easily be added to your existing ones:

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

This becomes really powerful when paired with `update` which handles all of the `UndoList` actions seamlessly.

```elm
update
  : (action -> model -> model)
  -> (Action action -> UndoList model -> UndoList model)
```

This lets you write a normal `update` function and then upgrade it to a function that works on `UndoLists`.

The API has a lot more cool stuff, so [check it out][docs].

[docs]: http://package.elm-lang.org/packages/TheSeamau5/elm-undo-redo/latest

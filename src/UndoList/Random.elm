module UndoList.Random where
{-| Random UndoList Submodule.

Provides random undolist and undolist action generators.

# Generators
@docs undolist, action
-}


import UndoList     exposing (UndoList, Action(..))
import Random       exposing (Generator, list)
import Random.Extra exposing (map, map3, frequency, constant)


{-| Random UndoList Generator constructor.
Given a generator of state, a length for the past, and a length for the future,
generate a random undolist of states.

    undolist pastLength futureLength generator
-}
undolist : Int -> Int -> Generator state -> Generator (UndoList state)
undolist pastLength futureLength generator =
  map3 UndoList
    (list pastLength generator)
    (generator)
    (list futureLength generator)


{-| Generate random undolist actions given an action generator.

Generates actions with the following probabilities:

- Reset  : 5%
- Forget : 5%
- Undo   : 30%
- Redo   : 30%
- New    : 30%
-}
action : Generator action -> Generator (Action action)
action generator =
  frequency
    [ (1, constant Reset)
    , (1, constant Forget)
    , (6, constant Undo)
    , (6, constant Redo)
    , (6, map New generator)
    ] (constant Reset)

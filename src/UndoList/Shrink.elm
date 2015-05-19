module UndoList.Shrink where
{-| Shrink UndoList Submodule.

Provides shrinking strategies for timelines and actions.

# Shrinkers
@docs undolist, action

-}

import Shrink   exposing (Shrinker, map, list)
import UndoList exposing (UndoList, Action(..))
import List


{-| Shrink an undo-list of states given a shrinker of states.
-}
undolist : Shrinker state -> Shrinker (UndoList state)
undolist shrinker {past, present, future} =
  let
      --pasts : List (List state)
      pasts = list shrinker past

      --futures : List (List state)
      futures = list shrinker future

      --presents : List state
      presents = shrinker present


  in
         List.map  (\past     -> UndoList past present future) pasts
      ++ List.map  (\present  -> UndoList past present future) presents
      ++ List.map  (\future   -> UndoList past present future) futures
      ++ List.map2 (\past present   -> UndoList past present future) pasts presents
      ++ List.map2 (\past future    -> UndoList past present future) pasts futures
      ++ List.map2 (\present future -> UndoList past present future) presents futures
      ++ List.map3 UndoList pasts presents futures



{-| Shrink an undo-list action given an action shrinker.
Considers `Reset` to be most minimal.
-}
action : Shrinker action -> Shrinker (Action action)
action shrinker action' =
  case action' of
    Reset ->
      []

    Forget ->
      [ Reset ]

    Undo ->
      [ Forget, Reset ]

    Redo ->
      [ Undo, Forget, Reset ]

    New action' ->
      Undo :: Redo :: Forget :: Reset :: map New (shrinker action')

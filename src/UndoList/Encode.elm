module UndoList.Encode where
{-| Encode UndoList submodule.

Provides JSON encoders for Timelines and UndoList Actions.

# Encoders
@docs undolist, action

-}

import UndoList     exposing (UndoList(..), Action(..))
import Json.Encode  exposing (Value, object, list, string)

{-| Encode an undolist of JSON values.
Best paired with the `map` function from UndoList.

    encodeUndoList stateEncoder  =
      UndoList.map stateEncoder >> undolist
-}
undolist : UndoList Value -> Value
undolist (UndoList past present future) =
  object
    [ ("past"   , list past   )
    , ("present", present     )
    , ("future" , list future )
    ]



{-| Encode an UndoList Action of JSON values.
Best paired with the `mapAction` function from UndoList.

    encodeAction actionEncoder =
      UndoList.mapAction actionEncoder >> action
-}
action : Action Value -> Value
action action' =
  case action' of
    Reset ->
      string "Reset"

    Redo ->
      string "Redo"

    Undo ->
      string "Undo"

    Forget ->
      string "Forget"

    New value ->
      object
        [ ("New", value) ]

import Html
import Html.Events exposing (onClick)
import Signal exposing (mailbox)
import UndoList exposing (UndoList, Action(..))

-------------------------------
-- Version with undo support --
-------------------------------

initial = 0

update _ state = state + 1

view address state =
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
  Signal.map (UndoList.view view address)
    (Signal.foldp (UndoList.apply update) (UndoList.fresh initial) signal)



----------------------------------
-- Version without undo support --
----------------------------------

{-}
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
-}

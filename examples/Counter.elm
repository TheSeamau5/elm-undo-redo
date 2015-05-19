import Html
import Html.Events exposing (onClick)
import Signal exposing (mailbox)
import UndoList exposing (UndoList(..), Action(..), fresh, apply)

-------------------------------
-- Version with undo support --
-------------------------------

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

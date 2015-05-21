import Html exposing (Html)
import Html.Events exposing (on, targetValue, onClick)
import Html.Attributes exposing (style, value, placeholder)
import Signal exposing (Signal, Address, Mailbox, mailbox)
import UndoList exposing (Action(..))

-------------------
-- View Function --
-------------------

view : Address (Action String) -> String -> Html
view address state =
  let
      button value =
        Html.button
            [ onClick address value
            , style
                [ "width"     => "8em"
                , "height"    => "3em"
                , "font-size" => "14pt"
                ]
            ]
            [ Html.text (toActionString value) ]

      undoButton =
        button Undo

      redoButton =
        button Redo

      title =
        Html.span
            [ style
                [ "font-size" => "16pt" ]
            ]
            [ Html.text "Simple Text Area with Undo/Redo support" ]

      headerArea =
        Html.div
            [ style
                [ "display"         => "flex"
                , "justify-content" => "space-between"
                , "align-items"     => "center"
                ]
            ]
            [ undoButton
            , title
            , redoButton
            ]



      textArea =
        Html.textarea
            [ on "input" targetValue (New >> Signal.message address)
            , value state
            , placeholder "Enter text here..."
            , style
                [ "flex"        => "1"
                , "font-size"   => "24pt"
                , "font-family" => "Helvetica Neue, Helvetica, Arial, sans-serif"
                , "resize"      => "none"
                ]
            ]
            []

  in
      Html.div
          [ style
              [ "position"        => "absolute"
              , "margin"          => "0"
              , "padding"         => "0"
              , "width"           => "100vw"
              , "height"          => "100vh"
              , "display"         => "flex"
              , "flex-direction"  => "column"
              ]
          ]
          [ headerArea
          , textArea
          ]

-------------------
-- Initial State --
-------------------
-- The initial state of the entire application
initial : String
initial = ""

------------------
-- Update State --
------------------

-- Update current state by replacing it with the input.
update : String -> String -> String
update action _ = action

-------------
-- Mailbox --
-------------

-- This is a mailbox of UndoList.Action
{address, signal} = mailbox Reset

----------
-- Main --
----------

-- The main function.
main : Signal Html
main =
  Signal.map (UndoList.view view address)
    (UndoList.foldp update initial signal)

----------------------
-- Helper Functions --
----------------------

(=>) = (,)

toActionString action =
  case action of
    New a -> "New " ++ toString a
    Undo -> "Undo"
    Redo -> "Redo"
    Forget -> "Forget"
    Reset -> "Reset"

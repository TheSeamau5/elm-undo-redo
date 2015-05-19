import Check exposing (..)
import Check.Investigator exposing (..)
import Check.Runner.Browser exposing (..)

import Test.Investigator.UndoList exposing (..)
import Test.Investigator.Action exposing (..)

import UndoList exposing (UndoList(..), Action(..))
import UndoList.Decode as Decode
import UndoList.Encode as Encode
import UndoList.Shrink

import Json.Decode as Decode exposing (Decoder, decodeValue)
import Json.Encode as Encode exposing (Value)

import Random
import List
import Maybe

main =
  check suite_package 10000 (Random.initialSeed 872620)
  |> display


suite_package =
  suite "Test Suite for elm-undo-redo"
    [ suite_undolist
    , suite_state_machine
    ]


-------------------------
-- State Machine Suite --
-------------------------


suite_state_machine =
  suite "State Machine Tests"
    [ claim_state_machine_length ]


claim_state_machine_length =
  claim
    "State Machine is consistent with respect to length"
  `that`
    state_machine_update
  `is`
    state_machine_step
  `for`
    tuple (list (action int), undolist int)


state_machine_update : (List (Action Int), UndoList Int) -> List (Int, Int)
state_machine_update (actions, undolist) =
  actions
  |> List.map update
  |> pipe undolist
  |> List.map (\l -> (UndoList.lengthPast l, UndoList.lengthFuture l))


state_machine_step : (List (Action Int), UndoList Int) -> List (Int, Int)
state_machine_step (actions, undolist) =
  actions
  |> List.map step
  |> pipe (UndoList.lengthPast undolist, UndoList.lengthFuture undolist)





update action undolist =
  case action of
    Reset ->
      UndoList.reset undolist
    Redo ->
      UndoList.redo undolist
    Undo ->
      UndoList.undo undolist
    Forget ->
      UndoList.forget undolist
    New n ->
      UndoList.new n undolist


step action (pastLen, futureLen) =
  case action of
    Reset ->
      (0, 0)
    Redo ->
      if futureLen == 0
      then
        (pastLen, futureLen)
      else
        (pastLen + 1, futureLen - 1)
    Undo ->
      if pastLen == 0
      then
        (pastLen, futureLen)
      else
        (pastLen - 1, futureLen + 1)
    Forget ->
      (0, futureLen)
    New _ ->
      (pastLen + 1, 0)


pipe : state -> List (state -> state) -> List state
pipe state actions  =
  case actions of
    [] ->
      [ state ]
    f :: fs ->
      state :: pipe (f state) fs





---------------------
-- Undo List Suite --
---------------------

suite_undolist =
  suite "UndoList Suite"
    [ claim_encode_decode_inverse
    , claim_undolist_length_atleastone
    , claim_redo_does_not_change_length
    , claim_undo_does_not_change_length
    , claim_forget_produces_empty_past
    , claim_new_produces_empty_future
    , claim_new_adds_one_length_past
    , claim_undo_redo_inverse
    , claim_redo_undo_inverse
    , claim_new_then_undo_yields_same_present
    , claim_reset_equivalent_fresh_oldest
    ]




claim_reset_equivalent_fresh_oldest =
  claim
    "Resetting an undo list is equivalent to creating an undo list with the oldest state"
  `that`
    UndoList.reset
  `is`
    fresh_oldest
  `for`
    undolist int



fresh_oldest undolist =
  let
      present = UndoList.present undolist
  in
    undolist
    |> UndoList.past
    |> List.reverse
    |> List.head
    |> Maybe.withDefault present
    |> UndoList.fresh


claim_new_then_undo_yields_same_present =
  claim
    "Calling new then undo preserves the original present state"
  `that`
    (\(v, undolist) -> UndoList.new v undolist |> UndoList.undo |> UndoList.present)
  `is`
    (\(_, undolist) -> UndoList.present undolist)
  `for`
    tuple (int, undolist int)

claim_redo_undo_inverse =
  claim
    "Redo and undo are inverse operations"
  `that`
    redo_undo
  `is`
    identity
  `for`
    undolist int

claim_undo_redo_inverse =
  claim
    "Undo and redo are inverse operations"
  `that`
    undo_redo
  `is`
    identity
  `for`
    undolist int


undo_redo undolist =
  if UndoList.hasPast undolist
  then
    UndoList.undo (UndoList.redo undolist)
  else
    undolist


redo_undo undolist =
  if UndoList.hasFuture undolist
  then
    UndoList.redo (UndoList.undo undolist)
  else
    undolist


claim_new_adds_one_length_past =
  claim
    "Adding a new state adds one element to the past"
  `that`
    (\(v, undolist) -> UndoList.new v undolist |> UndoList.lengthPast)
  `is`
    (\(_, undolist) -> UndoList.lengthPast undolist + 1)
  `for`
    tuple (int, undolist int)

claim_new_produces_empty_future =
  claim
    "Adding a new state yields an empty future"
  `that`
    (\(v, undolist) -> UndoList.new v undolist |> UndoList.lengthFuture)
  `is`
    always 0
  `for`
    tuple (int, undolist int)


claim_forget_produces_empty_past =
  claim
    "After forgetting the past, the past of the undo list is empty"
  `that`
    (UndoList.forget >> UndoList.lengthPast)
  `is`
    always 0
  `for`
    undolist int


claim_redo_does_not_change_length =
  claim
    "Redo does not change the length of an undo list"
  `that`
    (UndoList.redo >> UndoList.length)
  `is`
    UndoList.length
  `for`
    undolist int


claim_undo_does_not_change_length =
  claim
    "Undo does change the length of an undo list"
  `that`
    (UndoList.undo >> UndoList.length)
  `is`
    UndoList.length
  `for`
    undolist int


claim_undolist_length_atleastone =
  claim
    "The length of an undo list is at least one"
  `true`
    (\undolist -> UndoList.length undolist >= 1)
  `for`
    undolist int


claim_encode_decode_inverse =
  claim
    "Encoding and decoding are inverse operations"
  `that`
    encode_then_decode Encode.int Decode.int
  `is`
    Ok
  `for`
    undolist int

encode_then_decode : (state -> Value) -> Decoder state -> UndoList state -> Result String (UndoList state)
encode_then_decode encoder decoder undolist =
  let
      encoded =
        undolist
        |> UndoList.map encoder
        |> Encode.undolist

      decoded =
        decodeValue (Decode.undolist decoder) encoded
  in
      decoded

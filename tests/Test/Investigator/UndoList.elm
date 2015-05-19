module Test.Investigator.UndoList where


import Check.Investigator exposing (Investigator, investigator)
import UndoList exposing (UndoList(..), Action(..))
import UndoList.Random as Random
import UndoList.Shrink as Shrink
import Random
import Random.Extra exposing (flatMap2)


undolist : Investigator state -> Investigator (UndoList state)
undolist {generator, shrinker} =
  let
      gen =
        flatMap2
          (\p f -> Random.undolist p f generator)
          (Random.int 0 100)
          (Random.int 0 100)


      shr =
        Shrink.undolist shrinker
  in
      investigator gen shr

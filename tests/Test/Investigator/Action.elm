module Test.Investigator.Action where

import UndoList exposing (Action(..))
import UndoList.Random as Random
import UndoList.Shrink as Shrink

import Check.Investigator exposing (Investigator, investigator)
import Random
import Random.Extra


action : Investigator action -> Investigator (Action action)
action {generator, shrinker} =
  let
      gen =
        Random.action generator

      shr =
        Shrink.action shrinker
  in
      investigator gen shr

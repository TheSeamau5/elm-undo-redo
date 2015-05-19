module UndoList where
{-| UndoList Data Structure.

# Definition
@docs UndoList

# Basic Operations
@docs undo, redo, fresh, new, forget, reset

# Query UndoList
@docs past, present, future, hasPast, hasFuture, length, lengthPast, lengthFuture

# Actions
@docs Action, mapAction

# Functional Operations
@docs map, mapPresent, apply, connect, reduce, foldl, foldr, reverse, flatten, flatMap, andThen, map2, andMap

# Shorthands
@docs foldp, mailbox

# Conversions
@docs toList, fromList
-}

import List
import Signal exposing (Signal, Mailbox)


-------------------
-- UndoList Type --
-------------------

{-| The UndoList data structure.
An UndoList has:

1. A list of past states
2. A present state
3. A list of future states

    UndoList past present future

The head of the past list is the most recent state and the head of the future
list is the next state. (i.e., the tails of both lists point away from the
present)
-}
type UndoList state
  = UndoList (List state) state (List state)


-------------------------------
-- Basic UndoList Operations --
-------------------------------

{-| If the undolist has any past states, set the most recent past
state as the current state and turn the old present state into
a future state.

i.e.

    undo (UndoList [3,2,1] 4 [5,6]) == UndoList [2,1] 3 [4,5,6]
-}
undo : UndoList state -> UndoList state
undo (UndoList past present future) =
  case past of
    [] ->
      UndoList past present future

    x :: xs ->
      UndoList xs x (present :: future)


{-| If the undo-list has any future states, set the next
future state as the current state and turn the old present state
into a past state.

i.e.

    redo (UndoList [3,2,1] 4 [5,6]) == UndoList [4,3,2,1] 5 [6]
-}
redo : UndoList state -> UndoList state
redo (UndoList past present future) =
  case future of
    [] ->
      UndoList past present future

    x :: xs ->
      UndoList (present :: past) x xs


{-| Turn a state into an undo-list with neither past nor future.
-}
fresh : state -> UndoList state
fresh state =
  UndoList [] state []

{-| Add a new present state to the undo-list, turning the old
present state into a past state and erasing the future.
-}
new : state -> UndoList state -> UndoList state
new event (UndoList past present _ ) =
  UndoList (present :: past) event []


{-| Forget the past and look to the future!
This simply clears the past list.

i.e.
    forget (UndoList [3,2,1] 4 [5,6]) == UndoList [] 4 [5,6]
-}
forget : UndoList state -> UndoList state
forget (UndoList _ present future) =
  UndoList [] present future


{-| Reset the undo-list by returning to the very first state
and clearing all other states.

i.e.

    reset (UndoList [3,2,1] 4 [5,6]) == UndoList [] 1 []
-}
reset : UndoList state -> UndoList state
reset (UndoList past present _ ) =
  case past of
    [] ->
      fresh present

    x :: xs ->
      reset (UndoList xs x [])




----------------------
-- UndoList Queries --
----------------------

{-| Get the present state of the undo-list.
-}
present : UndoList state -> state
present (UndoList _ present' _) = present'

{-| Get all the past states of the undo-list.
Remember: the head of the list is the most recent state.
-}
past : UndoList state -> List state
past (UndoList past' _ _) = past'

{-| Get all the future state of the undo-list.
-}
future : UndoList state -> List state
future (UndoList _ _ future') = future'


{-| Check if the undo-list has any past states.
-}
hasPast : UndoList state -> Bool
hasPast =
  past >> List.isEmpty

{-| Check if the undo-list has any future states.
-}
hasFuture : UndoList state -> Bool
hasFuture =
  future >> List.isEmpty


{-| Get the full length of an undo-list
-}
length : UndoList state -> Int
length undolist =
  lengthPast undolist + 1 + lengthFuture undolist

{-| Get the length of the past.
-}
lengthPast : UndoList state -> Int
lengthPast =
  past >> List.length

{-| Get the length of the future
-}
lengthFuture : UndoList state -> Int
lengthFuture =
  future >> List.length

--------------------------
-- UndoList Action Type --
--------------------------

{-| Simple UndoList Action type. This is a simple type that can be used for
most use cases. This works best when paired with the `apply` function as
`apply` will perform the corresponding operations on the undolist automatically.

Consider using your own data type only if you really need it.
-}
type Action action
  = Reset
  | Redo
  | Undo
  | Forget
  | New action



{-| Map a function over an action.
-}
mapAction : (a -> b) -> Action a -> Action b
mapAction f action =
  case action of
    Reset -> Reset
    Redo  -> Redo
    Undo  -> Undo
    Forget -> Forget
    New action' -> New (f action')



---------------------------
-- Functional Operations --
---------------------------

{-| Map a function over an undo-list.
Be careful with this. The function will be applied to the past and the future
as well. If you just want to change the present, use `mapPresent`.

A good use case for `map` is to encode an undo-list as JSON.

Example:

    import UndoList.Encode as Encode

    encode encoder undolist =
      map encoder undolist
      |> Encode.undolist
-}
map : (a -> b) -> UndoList a -> UndoList b
map f (UndoList past present future) =
  UndoList (List.map f past) (f present) (List.map f future)


map2 : (a -> b -> c) -> UndoList a -> UndoList b -> UndoList c
map2 f (UndoList pastA presentA futureA) (UndoList pastB presentB futureB) =
  UndoList (List.map2 f pastA pastB) (f presentA presentB) (List.map2 f futureA futureB)


andMap : UndoList (a -> b) -> UndoList a -> UndoList b
andMap =
  map2 (<|)

{-| Apply a function only on the present.
-}
mapPresent : (a -> a) -> UndoList a -> UndoList a
mapPresent f (UndoList past present future) =
  UndoList past (f present) future


{-| Convert a function that updates the state to a function that updates an undo-list.
This is very useful to allow you to write update functions that only deal with
the individual states of your system and treat undo/redo as an add on.


Example:

    -- Your update function
    update action state =
      case action of
        ... -- some implementation

    -- Your new update function
    update' = apply update

-}
apply : (action -> state -> state) -> Action action -> UndoList state -> UndoList state
apply update action undolist =
  case action of
    Reset ->
      reset undolist

    Redo  ->
      redo undolist

    Undo  ->
      undo undolist
    Forget ->
      forget undolist

    New action ->
      new (update action (present undolist)) undolist

{-| Alias for `foldl`
-}
reduce : (a -> b -> b) -> b -> UndoList a -> b
reduce = foldl

{-| Reduce an undo-list from the left (or from the past)
-}
foldl : (a -> b -> b) -> b -> UndoList a -> b
foldl reducer initial (UndoList past present future) =
  List.foldr reducer initial past
  |> reducer present
  |> (\b -> List.foldl reducer b future)


{-| Reduce an undo-list from the right (or from the future)
-}
foldr : (a -> b -> b) -> b -> UndoList a -> b
foldr reducer initial (UndoList past present future) =
  List.foldr reducer initial future
  |> reducer present
  |> (\b -> List.foldl reducer b past)


{-| Reverse an undo-list.
-}
reverse : UndoList a -> UndoList a
reverse (UndoList past present future) =
  UndoList future present past


{-| Flatten an undo-list.
-}
flatten : UndoList (UndoList a) -> UndoList a
flatten (UndoList pastTimelines (UndoList past present future) futureTimelines) =
  UndoList
    (past ++ List.reverse (List.concatMap toList pastTimelines))
    (present)
    (future ++ List.concatMap toList futureTimelines)


flatMap : (a -> UndoList b) -> UndoList a -> UndoList b
flatMap f =
  map f >> flatten


andThen : UndoList a -> (a -> UndoList b) -> UndoList b
andThen =
  flip flatMap


{-| Connect two undo-lists end to end. The present of the first undolist is
considered the present of the output undolist.
-}
connect : UndoList state -> UndoList state -> UndoList state
connect (UndoList past present future) undolist =
  UndoList past present (future ++ toList undolist)


----------------
-- Shorthands --
----------------

{-| Analog of Signal.foldp

This shorthand is defined simple as follows:

    foldp update initial =
      Signal.foldp (apply update) (fresh initial)

This allows you to foldp on undo-lists without having to explicitly sprinkle
in undolist-specific code.
-}
foldp : (action -> state -> state) -> state -> Signal (Action action) -> Signal (UndoList state)
foldp update initial =
  Signal.foldp (apply update) (fresh initial)


{-| Shorthand for

    Signal.mailbox << New

Allows you to create a mailbox of undo-list actions given an action.

In many cases, you might be better off just doing:

    myMailbox = Signal.mailbox Reset

This allows you to avoid the problem of coming up with an initial value for
your mailbox.
-}
mailbox : action -> Mailbox (Action action)
mailbox action =
  Signal.mailbox (New action)


-----------------
-- Conversions --
-----------------

{-| Convert an undo-list to a list :

    toList (UndoList [3,2,1] 4 [5,6]) == [1,2,3,4,5,6]
-}
toList : UndoList state -> List state
toList (UndoList past present future) =
  List.reverse past ++ [present] ++ future

{-| Convert a list to undolist. The provided state is used as the present
state and the list is used as the future states.

    fromList 1 [2,3,4] == UndoList [] 1 [2,3,4]
-}
fromList : state -> List state -> UndoList state
fromList present future =
  UndoList [] present future

/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
**/

package tictactopa.colset

/**
 * {0 Optimized module for computing sets of columns}
 *
 * If the number of elements is very small, a bitwise implementation is much more efficient than a AVL.
 * This implementation works as long as the number of elements is smaller than the bitwise, often 32.
**/

/**
 * For positives int only.
 * 0 is authorized.
**/
type ColSet.elt = int

/**
 * The type of a set of elements of type [ColSet.elt]
**/
@abstract
type ColSet.t = int

@both @public ColSet = {{

  empty = 0 : ColSet.t

  is_empty(set : ColSet.t) = set == empty

  mem(i : ColSet.elt, set : ColSet.t) : ColSet.elt =
    Bitwise.land(1, Bitwise.lsr(set, i))

  add(i : ColSet.elt, set : ColSet.t) : ColSet.t =
    Bitwise.lor(set, Bitwise.lsl(1, i))

  inter = Bitwise.land : ColSet.t, ColSet.t -> ColSet.t
  union = Bitwise.lor : ColSet.t, ColSet.t -> ColSet.t

  fold(fold, set : ColSet.t, acc) =
    rec aux(elt, set, acc) =
      if set == 0 then acc
      else
        acc =
          if Bitwise.land(1, set) == 1
          then fold(elt, acc)
          else acc
        aux(succ(elt), Bitwise.lsr(set, 1), acc)
   aux(0, set, acc)

  map(map, set : ColSet.t) : ColSet.t =
    aux(elt, set) = add(map(elt), set)
    fold(aux, set, empty)

  iter(iter, set : ColSet.t) =
    aux(elt, _) = iter(elt) : void
    fold(aux, set, void)

  elements(set : ColSet.t) : list(ColSet.elt) =
    list = fold(List.cons, set, List.empty)
    List.rev(list)

  size(set : ColSet.t) =
    aux(_, acc) = succ(acc)
    fold(aux, set, 0)

  to_string(set : ColSet.t) =
    cons(hd, tl) = List.cons(string_of_int(hd), tl)
    list = fold(cons, set, List.empty)
    List.to_string(List.rev(list))

  /**
   * Folding intersection, but ignoring sets which
   * make the intersection become empty.
  **/
  specialize(setA : ColSet.t, setB : ColSet.t) =
    inter = inter(setA, setB)
    if is_empty(inter) then setA else inter

  /**
   * Pick a random elt in the set.
   * Returns [{none}] if the set is empty
  **/
  random(set : ColSet.t) : option(ColSet.elt) =
    rec aux(elt, set, size) =
      if set == 0 then none
      else
        if Bitwise.land(1, set) == 1
        then
          r = Random.int(size)
          if r == 0 then some(elt)
          else aux(succ(elt), Bitwise.lsr(set, 1), pred(size))
        else aux(succ(elt), Bitwise.lsr(set, 1), size)
    aux(0, set, size(set))

}}

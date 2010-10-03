/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Optimized module for computing sets of columns.
 * The number of columns is very small, a bitwise implementation is much more efficient than a AVL.
 * This implementation works as long as the elements are smaller than the bitwise, often 32.
**/

/**
 * For positives int only.
 * 0 is authorized.
**/
type ColSet.elt = int

/**
 * @abstract
**/
type ColSet.t = int

both ColSet = {{

  empty = 0

  is_empty(set) = set == empty

  mem(i, set) =
    Int.land(1, Int.lsr(set, i))

  add(i, set) =
    Int.lor(set, Int.lsl(1, i))

  inter = Int.land
  union = Int.lor

  fold(fold, set, acc) =
    rec aux(elt, set, acc) =
      if set == 0 then acc
      else
        acc =
          if Int.land(1, set) == 1
          then fold(elt, acc)
          else acc
        aux(succ(elt), Int.lsr(set, 1), acc)
   aux(0, set, acc)

  map(map, set) =
    aux(elt, set) = add(map(elt), set)
    fold(aux, set, empty)

  iter(iter, set) =
    aux(elt, _) = iter(elt) : void
    fold(aux, set, void)

  elements(set) =
    list = fold(List.cons, set, List.empty)
    List.rev(list)

  size(set) =
    aux(_, acc) = succ(acc)
    fold(aux, set, 0)

  /**
   * Folding intersection, but ignoring sets which
   * make the intersection become empty.
  **/
  priority_inter(list : list(ColSet.t), set : ColSet.t) =
    fold_inter(set, acc) =
      inter = inter(acc,set)
      if is_empty(inter) then acc else inter
    match list with
    | { nil } -> empty
    | ~{ hd tl } ->
      List.fold(fold_inter, tl, hd)

  /**
   * Pick a random elt in the set.
   * Returns { none } if the set is empty
  **/
  random(set) =
    rec aux(elt, set, size) =
      if set == 0 then none
      else
        if Int.land(1, set) == 1
        then
          r = Random.int(size)
          if r == 0 then some(elt)
          else aux(succ(elt), Int.lsr(set, 1), pred(size))
        else aux(succ(elt), Int.lsr(set, 1), size)
    aux(0, set, size(set))

}}

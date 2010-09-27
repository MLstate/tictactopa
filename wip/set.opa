/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

type Set.t('elt) = @todo

type Set.Order.SIG('elt) = {{			   
  compare : 'elt, 'elt -> int ;
  to_string : 'elt -> string ;
}}

type Set.t('elt) = 
  { nil } 
  / { key : 'elt ; left : Set.t('elt) ; right : Set.t('elt) }

MakeSet (Order : Set.Order.SIG('elt)) = {{

  inter(set, set') = @todo

  elements(set) =
    rec aux(set) =
      match set with
      | { nil } -> { nil }
      | ~{ key left right } -> List.concat(aux(left), List.cons(key, aux(right)))
    aux(set)

  iter(iter, set) =
    rec aux(set) =
      match set with
      | { nil } -> void
      | ~{ left key right } -> 
        do aux left 
        do iter key 
        aux right
    aux(set)

  fold(acc, fold, set) = @todo

  map(map, set) = @todo

  print(set) = @todo

  priority_inter(list) =
    fold_inter(acc, set) =
      inter = inter(acc,set)
      if is_empty(inter) then acc else inter
    match list with
    | { nil } -> { nil }
    | ~{ hd tl } ->
      List.fold(hd, fold_inter, tl)

  random(set) = @todo
  
}} : Set.SIG('elt)

/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Implementation of Game Interfaces
**/

GameContent = {{

  compare(content, content') =
    match content, content' with
    | { free }, { free } -> 0
    | { free }, _ -> -1
    | _, { free } -> 1
    | { O }, { O } -> 0
    | { O }, _ -> -1
    | _, { O } -> 1

  equal(content, content') = compare(content, content') == 0

  neg_player(player) =
    match player with
    | { X } -> { O }
    | { O } -> { X }  

  neg(content) =
    match content with
    | { free } -> content
    | player -> neg_player(player)

}} : GameContent.SIG

GameUtils = {{

  count(grid, content) =
    fold(acc, c) =
      if GameContent.equal(content, c) then succ(acc) else acc
    Grid.fold(0, fold, grid)

  count_check(grid) =
    // optimize, get X and O in one traversal of grid
    fold(((x,o) as acc), cont) =
      match cont with
      | { free } -> acc
      | { X } -> succ(x), o
      | { O } -> x, succ(o)
    (x, o) = Grid.fold((0,0), fold, grid)
    (x >= o) && (x - o <= 1)

  free(grid, location) = GameContent.equal(Grid.get(grid, location), {free})

  free_line(grid, column) =
   lines = Grid.dimensions(grid).lines
   loc(i) = { column = column ; line = i }
   rec aux(i) =
     if i == lines then { none } else
     if free(grid, loc(i)) then { some = i } else aux(succ(i))
   aux(0)

  count_contact(grid, content, location) =
    fold(acc, c) =
      if GameContent.equal(content, c) then succ(acc) else acc
    Grid.fold_neibourgh(0, fold, grid, location)

  unsafe_add = Grid.set

}} : GameUtils.SIG

GameRules = {{

  who_plays(grid, player) =
    x = count(grid, { X })
    o = count(grid, { O })
    if x == o then { X } else { O }

  validate(grid, action) = GameUtils.free_line(grid, action) <> { none }

  actions(grid) =
    columns = Grid.dimensions(grid).columns
    rec aux(set, i) =
      if i == columns then set else
        set = if validate(grid, i) then Set.add(i, set) else set
        aux(set, succ(i))
    aux(Set.empty, 0)

  status(grid) = @todo

}} : GameRules.SIG

Game = {{

  play(grid, action) =
    match GameRules.status(grid) with
    | { in_progress = player } ->
      match free_line(grid, action) with
      | { some = line } ->
        loc = { column = action ; line = line }
        Grid.set(grid, loc, player) 
      | { none } -> @fail
      end
    | _ -> @fail

  remove(grid, column) =
    columns = Grid.dimensions(grid).columns
      match free_line(grid, action) with
      | { some = line } ->
        pline = pred(line)
        if pline >= 0 then
          loc = { column = column ; line = pline }
          Grid.set(grid, loc, { free })
        else grid 
      | { none } -> grid
    
}}

/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Implementation of Grid Interfaces
**/

type Grid.t('parameters, 'content) = @todo

Grid = {{

  dimensions(grid) = @todo

  make(dimension, alpha) = @todo

  get(grid, location) = @todo

  set(grid, location, alpha) = @todo
 
  clear(grid, alpha) = @todo

  parameters(grid) = @todo

}} : Grid.SIG

GridUtils = {{

  differential(diff, int) =
    match diff with
    | { zero } -> int
    | { pred } -> int - 1
    | { succ } -> int + 1

}} : GridUtils.SIG

/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
 */

package tictactopa.ia
import tictactopa.{colset,grid,game}

/**
 * Implementation of IA.
**/

/**
 * {1 Types}
**/

/**
 *
**/
type IA.parameters = {level : int}

/**
 * We use a 2 dimension Grid for seing if a location make a player win.
 * A location is 'winning' if the fact to play there make the grid be winning for that player.
 * We ignore non-free location, the winning status of a non free location is [false, false]
**/
type IA.winning_location = {
  R : bool ;
  Y : bool ;
}

type IA.winning_grid = Grid.t(IA.winning_location)


/**
 * The state of the IA.
 * Just to avoid multi allocation of huge structure.
**/
type IA.state = {
  winning_grid : IA.winning_grid ;
}

/**
 * {1 Utils}
**/

IA_Winning = {{

  bottom = { R = false ; Y = false }

  read(winning : IA.winning_location, player : Game.player) =
    match player with
    | {R} -> winning.R
    | {Y} -> winning.Y

  /**
   * Just so that compute_winning_grid can have an imperative
   * implementation for not reallocating a fresh winning_grid
  **/
  make(dimensions : Grid.dimensions) : IA.winning_grid =
    Grid.make(dimensions, bottom)

  @private reset(win : IA.winning_grid) =
    Grid.clear(win, bottom)

  /**
   * Compute a winning table.
   * The interface is so that we can use an imperative or a persistent
   * implementation for the winning_grid.
  **/

  // utils. assert: the location is free
  @private winning_ij(grid, i, j, player : Game.content) =
    grid = Grid.setij(grid, i, j, player)
    res =
      match GameUtils.status(grid) with
      | { some = p } ->
        // FIXME: The typer does not work with p <: Game.content, without the coercion
        p = ( p : Game.player ) <: Game.content
        GameContent.equal(player, p)
      | _ -> false
    grid = Grid.setij(grid, i, j, {free})
    res

  compute(grid : Game.grid, win : IA.winning_grid) : IA.winning_grid =
    win = reset(win)
    iter(i, j) =
      if Grid.getij(grid, i, j) == { free }
      then
        R_winning = winning_ij(grid, i, j, {R})
        Y_winning = winning_ij(grid, i, j, {Y})
        winning = { R = R_winning ; Y = Y_winning }
        _ = Grid.setij(win, i, j, winning)
        void
    do Grid.iterij(grid, iter)
    win

  /**
   * Once the winning grid is computed, we can have a few interresting informations.
  **/

  /**
   * Return the set of action leading to the subite victory for the player [p]
   * given a start set of possible actions.
  **/
  victory(grid : Game.grid, win : IA.winning_grid, actions : ColSet.t, p : Game.player) =
    fold(column, acc) =
      match GameUtils.free_line(grid, column) with
      | { some = line } ->
        w = Grid.getij(win, column, line)
        if read(w, p)
        then ColSet.add(column, acc)
        else acc
      | _ -> acc
    actions = ColSet.fold(fold, actions, ColSet.empty)
    actions

  /**
   * In a set of actions, remove the one making so that the player [p] can play up and win.
   * The only possibility for this situation, is so that the location just up the action was
   * already winning
  **/
  anti_victory(grid : Game.grid, win : IA.winning_grid, actions : ColSet.t, p : Game.player) =
    dimensions = Grid.dimensions(grid)
    lines = dimensions.lines
    fold(column, acc) =
      match GameUtils.free_line(grid, column) with
      | { some = line } ->
        succ_line = succ(line)
        if succ_line >= lines then acc
        else
          w = Grid.getij(win, column, succ_line)
          if read(w, p)
          then acc
          else ColSet.add(column, acc)
      | _ -> acc
    actions = ColSet.fold(fold, actions, ColSet.empty)
    actions
}}

/**
 * {1 Main IA module}
**/

/**
 * Actually, there are no reason to restrict the IA to the server side.
 * We can see what happen if the IA is on the client :)
**/

@both @public IA = {{

  Parameters = {{

    max_level = 4

    default = { level = 0 } : IA.parameters

    /**
     * Return a level in the bounds of the ia.
    **/
    check(level : IA.parameters) =
      i = level.level
      if i < 0
      then
        { level = 0 }
      else
        if i > max_level
        then
          { level = max_level }
        else
          level

  }}

  /**
   * Allocation of the state of the IA.
  **/
  allocate(grid : Game.grid) : IA.state =
    dimensions = Grid.dimensions(grid)
    winning_grid = IA_Winning.make(dimensions)
    state = ~{
      winning_grid ;
    }
    state

  /**
   * Main function
   * For simplicity, the IA is state less.
   * It bring a lot of flexibility for this simple game.
   * The status of the grid should be { in_progress } or
   * this will raise an error.
   * Since this is stateless, we can by using it add an url
   * to the application for having a web service to play the tictactoe
   *
   * The ia is state less, but there are some structure needed to be allocated.
   * So, we rather takes a state (just for GC-relax purpose)
  **/
  compute(game : Game.state) =
    state = game.ia_state
    level = game.ia.level
    player =
      match game.status with
      | { in_progress = player } -> player
      | _ -> @fail("IA.compute")
    grid = game.grid

    log(name, set) =
      repr = ColSet.to_string(set)
      jlog("{name} : {repr}")

    choices = GameRules.actions(grid)

    do jlog("========IA========")
    do log("choices", choices)

    // At the end, once the choices have beenn made,
    // select one of the remaining choices.
    choose(actions) =
      action = ColSet.random(actions)
      action =
        match action with
        | {none} -> @fail("IA.compute: internal error")
        | {some = action} -> action
      action : Game.action

    /*
     * Note: we keep this indentation for better readability.
     */

    // Level 0: play randomly
    if level == 0 then choose(choices) else

    other_player = GameContent.neg_player(player)
    win = IA_Winning.compute(grid, state.winning_grid)

    // Victory
    victory = IA_Winning.victory(grid, win, choices, player)
    do log("victory", victory)
    choices = ColSet.specialize(choices, victory)
    do log("choices", choices)

    // Blocking victory
    block_victory = IA_Winning.victory(grid, win, choices, other_player)
    do log("block_victory", block_victory)
    choices = ColSet.specialize(choices, block_victory)
    do log("choices", choices)

    // Anti-victory
    anti_victory = IA_Winning.anti_victory(grid, win, choices, other_player)
    do log("anti_victory", anti_victory)
    choices = ColSet.specialize(choices, anti_victory)
    do log("choices", choices)

    // This is enough for level 1
    if level <= 1 then choose(choices) else


    choose(choices)

}}

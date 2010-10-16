/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
 */

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

  /**
   * Just so that compute_winning_grid can have an imperative
   * implementation for not reallocating a fresh winning_grid
  **/
  make(dimensions : Grid.dimensions) : IA.winning_grid =
    Grid.make(dimensions, bottom)

  reset(win : IA.winning_grid) =
    Grid.clear(win, bottom)

  /**
   * Compute a winning table.
   * The interface is so that we can use an imperative or a persistent
   * implementation for the winning_grid.
  **/

  // utils. assert: the location is free
  @private winning_ij(grid, i, j, player : Game.content) =
    do Grid.setij(grid, i, j, player)
    res =
      match GameUtils.status(grid) with
      | { some = p } ->
        // FIXME: The typer is dummy, p :< Game.content does not work at all
        p = Magic.id(p) : Game.content
        GameContent.equal(player, p)
      | _ -> false
    do Grid.setij(grid, i, j, {free})
    res

  compute(grid : Game.grid, win : IA.winning_grid) : IA.winning_grid =
    do reset(win)
    iter(i, j) =
      if Grid.getij(grid, i, j) == { free }
      then
        R_winning = winning_ij(grid, i, j, {R})
        Y_winning = winning_ij(grid, i, j, {Y})
        winning = { R = R_winning ; Y = Y_winning }
        do Grid.setij(win, i, j, winning)
        void
    do Grid.iterij(grid, iter)
    win

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
    actions = GameRules.actions(grid)

    if level == 0
    then
      // Level 0: play randomly
      action = ColSet.random(actions)
      action =
        match action with
        | {none} -> @fail("IA.compute: internal error")
        | {some = action} -> action
      action : Game.action
    else
      win = IA_Winning.compute(grid, state.winning_grid)
      iterij(i, j) =
        w = Grid.getij(win, i, j)
        do if w.R then jlog("R: {i},{j} => win")
        do if w.Y then jlog("Y: {i},{j} => win")
        void
      do Grid.iterij(win, iterij)
      action = ColSet.random(actions)
      action =
        match action with
        | {none} -> @fail("IA.compute: internal error")
        | {some = action} -> action
      action : Game.action


}}

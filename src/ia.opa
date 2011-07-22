/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
 */

package tictactopa.game
import tictactopa.{colset,grid}

/**
 * Implementation of IA.
**/

/**
 * {1 Types}
**/

/**
 * The type representing the level of the IA
**/
type IA.level = int

/**
 * Supported level of the IA.
**/
type IA.parameters = {level : IA.level}

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

  bottom = { R = false ; Y = false } : IA.winning_location

  /**
   * Reads the field corresponding to the player
  **/
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
    _grid = Grid.setij(grid, i, j, {free})
    res

  /**
   * Compute a winning table.
   * The interface is so that we can use an imperative or a persistent
   * implementation for the winning_grid.
  **/
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
   * Return a possible action leading to the subite victory for the player [p]
   * given a start set of possible actions.
  **/
  victory(grid : Game.grid, win : IA.winning_grid, actions : ColSet.t, p : Game.player) =
    find(column) =
      match GameUtils.free_line(grid, column) with
      | { some = line } ->
        w = Grid.getij(win, column, line)
        read(w, p)
      | _ -> false
    ColSet.find(find, actions)

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
 * Forced strategy
**/

IA_Forced = {{

  /**
   * Given a set of actions, find a possible action leading to a force strategy.
   * The winning_grid given in argument is modified and corrupted by this function.
  **/
  rec force_strategy(grid : Game.grid, win : IA.winning_grid, actions : ColSet.t, p : Game.player) =
    p2 = GameContent.neg_player(p)
    find(column) =
      // we play in that column, and see if it leads to a force strategy
      match GameUtils.free_line(grid, column) with
      | { none } -> false
      | { some = line } ->
        do jlog("force: trying to play {column}, {line}")
        grid = Grid.setij(grid, column, line, p <: Game.content)
        win = IA_Winning.compute(grid, win)
        forced =
          match IA_Winning.victory(grid, win, actions, p) with
          | { some = block } as some ->
            do jlog("force: this force the other to block me in {block}")
            some
          | { none } ->
            // a forced may be if anti_victory is a singleton
            p2_actions = GameRules.actions(grid)
            anti = IA_Winning.anti_victory(grid, win, p2_actions, p2)
            ColSet.is_singleton(anti)
        match forced with
        | {none} ->
          do jlog("force: this does not force the other to play anything, rolling back {column}, {line}")
          _ = Grid.setij(grid, column, line, {free})
          false
        | { some = forced } ->
          match GameUtils.free_line(grid, forced) with
          | {none} ->
            do jlog("force: internal error")
            _ = Grid.setij(grid, column, line, {free})
            false
          | {some = forced_line} ->
            do jlog("force: this force the other to play {forced}, {forced_line}")
            grid = Grid.setij(grid, forced, forced_line, p2 <: Game.content)
            win = IA_Winning.compute(grid, win)
            match IA_Winning.victory(grid, win, actions, p) with
            | { some = victory } ->
              do jlog("force: and after that, I will have victory in {victory}")
              _ = Grid.setij(grid, column, line, {free})
              _ = Grid.setij(grid, forced, forced_line, {free})
              true
            | { none } ->
              // recursive call
              // the force strategy should be computed in non victory choices
              // or in a force place
              actions =
                actions = GameRules.actions(grid)
                match IA_Winning.victory(grid, win, actions, p2) with
                | { some = p2_force } ->
                  ColSet.singleton(p2_force)
                | { none } ->
                  IA_Winning.anti_victory(grid, win, actions, p)
              if Option.is_some(force_strategy(grid, win, actions, p))
              then
                do jlog("force: and after that, I have noticed recursively that I find a strategy.")
                _ = Grid.setij(grid, column, line, {free})
                _ = Grid.setij(grid, forced, forced_line, {free})
                true
              else
                do jlog("force: this does not give me a deeper strategy, rolling back {column}, {line} and rolling back {forced}, {forced_line}")
                _ = Grid.setij(grid, column, line, {free})
                _ = Grid.setij(grid, forced, forced_line, {free})
                false
          end
        end
      end
    ColSet.find(find, actions)

  /**
   * Given a grid and an action, remove the actions leading to let the other to make a force strategy
  **/
  non_force_strategy(grid : Game.grid, win : IA.winning_grid, actions : ColSet.t, p : Game.player) =
    all_actions = GameRules.actions(grid)
    p2 = GameContent.neg_player(p)
    filter(column) =
      match GameUtils.free_line(grid, column) with
      | { none } -> false
      | { some = line } ->
        grid = Grid.setij(grid, column, line, p <: Game.content)
        match force_strategy(grid, win, all_actions, p2) with
        | { some = force } ->
          do jlog("non_force: removing {column} because other may force in {force}")
          _ = Grid.setij(grid, column, line, {free})
          false
        | { none } ->
          _ = Grid.setij(grid, column, line, {free})
          true
        end
      end
    ColSet.filter(filter, actions)
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

    max_level = 4 : IA.level

    default = { level = max_level } : IA.parameters

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
   * The status of the grid should be [{ in_progress }] or
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
    match victory with
    | {some = choice} ->
      do jlog("victory : {choice}")
      choice
    | _ ->

    // Blocking victory
    block_victory = IA_Winning.victory(grid, win, choices, other_player)
    match block_victory with
    | {some=choice} ->
      do jlog("blocking : {choice}")
      choice
    | _ ->

    // Anti-victory
    anti_victory = IA_Winning.anti_victory(grid, win, choices, other_player)
    do log("anti_victory", anti_victory)
    choices = ColSet.specialize(choices, anti_victory)
    do log("choices", choices)

    // This is enough for level 1
    if level <= 1 then choose(choices) else

    // If level is at least 3, we check for forced strategy
    forced =
      if level >= 3 then IA_Forced.force_strategy(grid, win, choices, player)
      else none

    match forced with
    | { some = choice } ->
      do jlog("forced strategy : {choice}")
      choice
    | _ ->

    choices =
      if level < 3 then choices else
        non_force = IA_Forced.non_force_strategy(grid, win, choices, player)
        do log("non_force", non_force)
        choices = ColSet.specialize(choices, non_force)
        do log("choices", choices)
        choices

    choose(choices)

}}

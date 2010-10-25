/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

package tictactopa.game
import tictactopa.{colset,grid}

/**
 * {0 Manipulation of the Game}
**/

/**
 * {1 Types}
**/

/**
 * {2 Content}
**/

/**
 * Representation of grid contents
 * Two players, { free } meaning the location is free.
 * Letter stands for red and yellow, the classical colors for this game.
**/

type Game.player = { R } / { Y }
type Game.content = Game.player / { free }

/**
 * {2 Action}
**/

/**
 * An action in the game.
 * It is also the choice of the decision algorithm.
 * In the tictactoe, actions are limited to a column choice.
**/
type Game.action = Grid.column



/**
 * {2 Status}
**/

/**
 * The analysis of a grid
 * + winner : the game is over, the player has win, or {none} for exaeco
 * + in_progress : the game is in progress, the player should play
 * + incoherent : an error occured, the content is incoherent
**/

type Game.winner = option(Game.player)

type Game.status =
  { winner : Game.winner } / { in_progress : Game.player } / { incoherent }

/**
 * {2 State}
**/

/**
 * {2 Parameters}
**/

/**
 * The number of token to win : 4
**/
type Game.goal = int

/**
 * {2 State}
**/

/**
 * The type of the main grid containing the game
**/
type Game.grid = Grid.t(Game.content)

/**
 * The full state of a game.
 * The status is cached for faster execution of some function of the module Game.
**/
type Game.state = {
  goal : Game.goal ;
  ia : IA.parameters ;
  ia_state : IA.state ;
  status : Game.status ;
  grid : Game.grid ;
}

/**
 * {1 Modules}
**/

/**
 * {2 Parameters}
**/

/**
 * Instance of constant parameters for this version of the game.
**/

@both @public GameParameters = {{

  /**
   * The first player to play, by convention.
  **/
  first_player = {Y} : Game.player

  /**
   * The dimensions of the grid.
  **/
  dimensions = { columns = 7 ; lines = 6 } : Grid.dimensions

  /**
   * The goal : how many token you need to align for the victory.
  **/
  goal = 4 : Game.goal

}}

/**
 * {2 FixTheTyper}
**/

/**
 * Probably unusefull if the type system upgrade.
 * restricted to the current package only.
 * Used in pattern matching only.
**/
@both @package FixTheTyper = {{
  player_of_content(c : Game.content) =
    match c with
    | {R}
    | {Y} -> Magic.id(c) : Game.player
    | _ -> error("Game.player_of_content")
}}

/**
 * {2 GameContent}
**/

@both @public GameContent = {{

  /**
   * { free } < { R } < { Y }
  **/
  compare(content : Game.content, content2 : Game.content) =
    match (content, content2) with
    | ({ free }, { free }) -> 0
    | ({ free }, _) -> -1
    | (_, { free }) -> 1
    | ({ R }, { R }) -> 0
    | ({ R }, _) -> -1
    | (_, { R }) -> 1
    | _ -> 0

  equal(content, content2) = compare(content, content2) == 0

  /**
   * Returns the negation of the Game.content.
   * The negation of { free } is { free }.
  **/
  neg_player(player) =
    match player : Game.player with
    | { R } -> { Y }
    | { Y } -> { R }

  neg(content) =
    match content : Game.content with
    | { free } -> content
    | player ->
      @opensums(neg_player(FixTheTyper.player_of_content(player))) : Game.content

  compare_player(p1 : Game.player, p2 : Game.player) =
    compare(@opensums(p1) : Game.content, @opensums(p2) : Game.content)

  equal_player(p1 : Game.player, p2 : Game.player) =
    equal(@opensums(p1) : Game.content, @opensums(p2) : Game.content)

}}

/**
 * {2 GameUtils}
**/

@both @public GameUtils = {{

 /**
   * Return the number of content present in the grid
  **/
  count(grid : Game.grid, content : Game.content) =
    fold(c, acc) =
      if GameContent.equal(content, c) then succ(acc) else acc
    Grid.fold(fold, grid, 0)

  /**
   * Check that the difference between player content.
   * {Y} is by convention the first to play.
   * #{Y}-1 <= #{R} <= #{Y}
  **/
  count_check(grid : Game.grid) =
    y = count(grid, {Y})
    r = count(grid, {R})
    (y >= r) && (y - r <= 1)

  /**
   * Say if a location is free
  **/
  free(grid : Game.grid, location : Grid.location) =
    Grid.get(grid, location) == { free }

  /**
   * Return the line index of the first free content
   * in a given column.
  **/
  free_line(grid : Game.grid, column : Grid.column) =
    dimensions = Grid.dimensions(grid)
    lines = dimensions.lines
    rec aux(line) =
      if line >= lines then none
      else
        location = ~{ column line }
        if free(grid, location) then some(line)
        else aux(succ(line))
    aux(0)

  /**
   * Return the number of content of a kind in contact
   * with a given content, at distance 1.
  **/
  count_contact(grid : Game.grid, content : Game.content, location : Grid.location) =
    fold(c, acc) =
      if GameContent.equal(content, c) then succ(acc) else acc
    Grid.fold_neibourgh(fold, grid, location, 1, 0)

  /**
   * Low level management of adding / removing contents, without
   * taking the gravity in consideration.
   * Not for casual user, restricted to the current package only.
  **/
  @package unsafe_set = Grid.set


  /**
   * Status detection:
   * From a non {free} case, follow from a location in a given direction as long as
   * the content does not change, or the value exceed goal. In this case, return the
   * corresponding player.
  **/
  follow(grid : Game.grid, i, j, direction : Grid.location) =
    goal = GameParameters.goal
    columns = GameParameters.dimensions.columns
    lines = GameParameters.dimensions.lines
    match Grid.getij(grid, i, j) with
    | {free} -> none
    | player ->
      di = direction.column
      dj = direction.line
      rec aux(dst, i, j) =
        // do jlog("  aux(dst:{dst}, {i}, {j}, di:{di}, dj:{dj})")
        if dst >= goal
        then
          player = FixTheTyper.player_of_content(player)
          some(player)
        else
          if (i < 0) || (j < 0) || (i >= columns) || (j >= lines)
          then none
          else
            content = Grid.getij(grid, i, j)
            if GameContent.equal(content, player)
            then aux(succ(dst), i+di, j+dj)
            else none
      aux(1, i+di, j+dj) : option(Game.player)

  /**
   * Follow in every direction (4), from every non-free location.
   * Stops with the first success
  **/
  status(grid : Game.grid) =
    h = { column = 1 ; line = 0 }
    v = { column = 0 ; line = 1}
    du = { column = 1 ; line = 1 }
    dd = { column = 1 ; line = -1 }
    columns = GameParameters.dimensions.columns
    lines = GameParameters.dimensions.lines
    rec aux(i, j) : option(Game.player) =
      if i >= columns then none
      else
        if j >= lines then aux(succ(i), 0)
        else
          // do jlog("aux({i}, {j})")
          match Grid.getij(grid, i, j) with
          | {free} -> aux(i, succ(j))
          | _ ->
            match follow(grid, i, j, h) with
            | ({some=_}) as some -> some
            | _ ->
              match follow(grid, i, j, v) with
              | ({some=_}) as some -> some
              | _ ->
                match follow(grid, i, j, du) with
                | ({some=_}) as some -> some
                | _ ->
                  match follow(grid, i, j, dd) with
                  | ({some=_}) as some -> some
                  | _ -> aux(i, succ(j))
                  end
                end
              end
            end
          end
    aux(0, 0)
}}

/**
 * {2 GameRules}
**/

@both @public GameRules = {{

  /**
   * Returns the player which need to play.
   * As a convention, { Y } is always the first
   * to play from an empty grid.
   *
   * In case of incohrence, this will return {R}
  **/
  who_plays(grid : Game.grid) =
    y = GameUtils.count(grid, { Y })
    r = GameUtils.count(grid, { R })
    if y == r then { Y } else { R }

  /**
   * Validate an action
  **/
  validate(grid : Game.grid, action : Game.action) =
    GameUtils.free_line(grid, action) != { none }

  /**
   * Compute possible actions.
   * In particular, If and only if the status is not
   * { in_progress }, the set will be empty.
  **/
  actions(grid : Game.grid) =
    columns = Grid.dimensions(grid).columns
    rec aux(i, set) =
      if i >= columns then set else
        set = if validate(grid, i) then ColSet.add(i, set) else set
        aux(succ(i), set)
    aux(0, ColSet.empty)

  /**
   * Determine the status of a grid
  **/
  status(grid) : Game.status =
    // fake implementation, just for testing
    fst = GameParameters.first_player
    snd = GameContent.neg_player(fst)
    n_fst =
      fst = @opensums(fst) : Game.content
      GameUtils.count(grid, fst)
    n_snd =
      snd = @opensums(snd) : Game.content
      GameUtils.count(grid, snd)
    total = GameParameters.dimensions.columns * GameParameters.dimensions.lines
    match GameUtils.status(grid) with
    | ({some=player}) as winner ->
      { winner = winner }
    | _ ->
      if total == n_fst + n_snd
      then
        { winner = none }
      else
        in_progress = if n_fst == n_snd then fst else snd
        { ~in_progress }

}}


/**
 * {2 Game}
**/

@both @public Game = {{

  make() =
    goal = GameParameters.goal
    // Convention: The Yellow are always the first to play
    status = { in_progress = GameParameters.first_player } : Game.status
    dimensions = GameParameters.dimensions
    content = { free } : Game.content
    grid = Grid.make(dimensions, content)
    ia = IA.Parameters.default
    ia_state = IA.allocate(grid)
    ~{ goal ia ia_state status grid }

  /**
   * Reseting only the grid and the status.
   * Preserve current IA level.
   * This is also an optimization for imperative implementation. Relax the GC
  **/
  reset(game) =
    status = { in_progress = GameParameters.first_player } : Game.status
    content = { free } : Game.content
    grid = Grid.clear(game.grid, content)
    { game with ~grid ~status }

  /**
   * Play an action in the game.
   * Assertion : checks should have been done previously.
   * We use the status of the game for knowing what player plays.
   * We return a game, updating its status.
   * This is a precondition of the function.
  **/
  play(game : Game.state, action : Game.action) =
    match game.status with
    | { in_progress = player } ->
      grid = game.grid
      column = action
      line = GameUtils.free_line(grid, column)
      match line with
      | {some = line} ->
        location = ~{ column line }
        /* Coercion of {b player} into {b Game.player} before opening
           the type to {b Game.content} is a handy workaround against the
           current @opensums bug in the typechecker
           (see test 02-subsums.opa).
           However, FIXME: @opensums(player) : Game.content */
        content = (player : Game.player) <: Game.content
        grid = Grid.set(grid, location, content)
        status = GameRules.status(grid)
        { game with ~grid ~status }
      | {none} ->
        @fail("Game.play")
      end
    | _ ->
      status = {incoherent}
      { game with ~status }
}}

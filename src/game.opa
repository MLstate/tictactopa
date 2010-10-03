/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Manipulation of the Game
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
type Game.status =
  { winner : option(Game.player) } / { in_progress : Game.player } / { incoherent }

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
 * The type of the main grid containing the game
**/
type Game.grid = Grid.t(Game.content)

// todo: move
type IA.parameters = int

/**
 * The full state of a game.
 * The status is cached for faster execution of some function of the module Game.
**/
type Game.state = {
  goal : Game.goal ;
  ia : IA.parameters ;
  status : Game.status ;
  grid : Game.grid ;
}

/**
 * Probably unusefull if the type system upgrade
**/
both FixTheTyper = {{
  player_of_content(c : Game.content) =
    match c with
    | {R}
    | {Y} -> Magic.id(c) : Game.player
    | _ -> error("Game.player_of_content")

  content_of_player(p : Game.player) = Magic.id(p) : Game.content
}}

both GameContent = {{

  /**
   * { free } < { R } < { Y }
  **/
  compare(content, content2) =
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
    match player with
    | { R } -> { Y }
    | { Y } -> { R }

  neg(content) =
    match content with
    | { free } -> content
    | player -> FixTheTyper.content_of_player(neg_player(FixTheTyper.player_of_content(player)))
}}

GameUtils = {{

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
   * Not for casual user
  **/
  unsafe_set = Grid.set

}}


GameRules = {{

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
  status(grid) = @fail("todo") // : Game.grid -> Game.status ;

}}

/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Manipulation of the Game
**/

/**
 * Representation of grid contents
 * Two players, { free } meaning the location is free.
 * Letter stands for red and yellow, the classical colors for this game.
**/

type Game.player = { R } / { Y }
type Game.content = Game.player / { free }

Game = {{

  /**
   * Probably unusefull if the type system upgrade
  **/
  player_of_content(c : Game.content) =
    match c with
    | {R}
    | {Y} -> Magic.id(c) : Game.player
    | _ -> error("Game.player_of_content")
}}

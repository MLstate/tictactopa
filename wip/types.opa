/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Types for game structures.
**/

/**
 * Dimensions of the game.
 *
 * Beware, the number of lines should be a multiple of 2 (precondition of the IA)
**/
type Grid.dimensions = {
  columns : int ;
  lines : int ;
}

/**
 * A location in a Grid.t
**/

type Grid.column = int
type Grid.line = int

type Grid.location = {
  column : Grid.column ;
  line : Grid.line ;
}

/**
 * Differential and orientation.
 * Line orientation : from down to up
 * Columns orientation : from left to rigth
**/

type Grid.differential = { succ } / { pred } / { zero }

type Grid.orientation = {
  column : Grid.differential ;
  line : Grid.differential ;
}

/**
 * The parameters of the game,
 * like the level of the computer.
**/

type IA.level = int
type Game.goal = int

type Game.parameters = {
  ia : IA.parameters ;
  goal : Game.goal ;
}

type IA.parameters = {
  level : IA.level ;
}

/**
 * Representation of grid contents
 * Two players, { free } meaning the location is free.
 * Letter stands for red and yellow, the classical colors for this game.
**/

type Game.player = { R } / { Y }
type Game.content = player / { free }

// Check-me : Type system
// Any function define on loc can accept a player instead ?

/**
 * An action in the game.
 * It is also the choice of the decision algorithm.
 * In the tictactoe, actions are limited to a column choice.
**/
type Game.action = Grid.column

/**
 * The analysis of a grid
 * + winner : the game is over, the player has win, or {none} for exaeco
 * + in_progress : the game is in progress, the player should play
 * + incoherent : an error occured, the content is incoherent
**/
type Game.status =
  { winner : option(player) } / { in_progress : player } / { incoherent }

/**
 * The type of the main grid containing the game
**/
type Game.grid = Grid.t(Game.parameters, Game.content)

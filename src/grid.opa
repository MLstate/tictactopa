/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Manipulation of the Grid
**/

/**
 * {1 Types}
**/

/**
 * Most of the types can be manipulated on both sides.
**/

/**
 * Dimensions of the game. 7 columns, 6 lines.
 *
 * Beware, the number of lines should be a multiple of 2 (precondition of the IA)
**/
type Grid.dimensions = {
  columns : int ;
  lines : int ;
}

/**
 * A location in a Grid.t
 *
 * Speeking as coordonates, we index (column X line),
 * with column and line starting from value 0
**/

type Grid.column = int
type Grid.line = int

type Grid.location = {
  column : Grid.column ;
  line : Grid.line ;
}

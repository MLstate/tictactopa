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
 * @public
**/

type Grid.column = int
type Grid.line = int

type Grid.location = {
  column : Grid.column ;
  line : Grid.line ;
}

/**
 * The dimensions are cached.
 * @abstract
**/
type Grid.t('content) = {
  dimensions : Grid.dimensions ;
  t : llarray(llarray('content)) ;
}

/**
 * {1 Manipulation of the Grid}
**/

/**
 * Important note:
 * The module for manipulating the grid is available on both side, but
 * each side has its own grid, there is no serialization of a grid.
 *
 * We could imagine serveral kind of clients, ligth or not.
 * E.g. a light client would not have the grid (only the server will),
 * where a heavyer client could before perform some checks locally before
 * sending action to the server which has anyway the grid for security reason.
**/

both Grid = {{

  /**
   * Creating a new grid.
  **/
  make(dimensions, content) =
    c = dimensions.columns
    l = dimensions.line
    line() = LowLevelArray.create(l, content)
    t = LowLevelArray.create(c, line())
    rec aux(i) =
      if i >= c then void
      else
        do LowLevelArray.set(t, i, line())
        aux(succ(i))
    do aux(1)
    ~{ dimensions t }

  /**
   * Get the dimensions of the grid.
  **/
  dimensions(grid : Grid.t) = grid.dimensions

  /**
   * @private
  **/
  private_get(grid : Grid.t, column : int, line : int) =
    t = grid.t
    t_line = LowLevelArray.get(t, column)
    content = LowLevelArray.get(t_line, line)
    content

  /**
   * Get the content of a location.
  **/
  get(grid : Grid.t, location : Grid.location) =
    private_get(grid, location.column, location.line)

  /**
   * Set the content of a location.
   * The interface in functionnal because we may switch the current implementation
   * for a persistent implementation.
  **/
  set(grid : Grid.t('content), location : Grid.location, content : 'content) =
    t = grid.t
    line = LowLevelArray.get(t, location.column)
    do LowLevelArray.set(line, location.line, content)
    grid

  /**
   * Utils: For loop
  **/
  for(min, max, iter) =
    rec aux(i) =
      if i > max then void else do iter(i) ; aux(succ(i))
    aux(min)

  /**
   * Clear the grid, which means fill with a given content.
  **/
  clear(grid : Grid.t('content), content :'content) =
    dimensions = grid.dimensions
    columns = dimensions.columns
    lines = dimensions.lines
    t = grid.t
    iter(i) =
      line = LowLevelArray.get(t, i)
      iter(j) = LowLevelArray.set(line, j, content)
      do for(0, pred(lines), iter)
      void
    do for(0, pred(columns), iter)
    grid

  /**
   * Fold. Column by column, and inside, line by line.
  **/
  fold(fold, grid, acc) =
    t = grid.t
    fold_line(line, acc) = LowLevelArray.fold(fold, line, acc)
    LowLevelArray.fold(fold_line, t, acc)

  /**
   * Fold neibourgh. Column by column, and inside, line by line.
   * The location itself is not folded.
  **/
  fold_neibourgh(fold, grid : Grid.t, location : Grid.location, dist : int, acc) =
    dimensions = grid.dimensions
    columns = dimensions.columns
    lines = dimensions.lines
    t = grid.t
    column = location.column
    line = location.line
    min_c = max(0, column - dist)
    max_c = min(columns - 1, column + dist)
    min_l = max(0, line - dist)
    max_l = min(lines - 1, line + dist)
    rec aux(i, j, acc) =
      if i > max_c then acc
      else
        if j > max_l then aux(succ(i), min_l, acc)
        else
          if ((i == column) && (j == line)) then aux(i, succ(j), acc)
          else
            acc = fold(private_get(grid, i, j), acc)
            aux(i, succ(j), acc)
    aux(min_c, min_l, acc)
}}

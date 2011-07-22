/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
**/

package tictactopa.grid

/**
 * {0 Manipulation of the Grid}
**/

/**
 * {1 Types}
**/

/**
 * Most of the types can be manipulated on both sides.
**/

/**
 * Dimensions of the game. 7 columns, 6 lines.
 * Beware, the number of lines should be a multiple of 2 (precondition of the IA).
 * Actually, the code looks like generic, and size-extensible, but the ClientLayout,
 * as well as the image used for drawing the table is not.
 * But, we'd like to be able to use this server lib with some other clients.
**/
type Grid.dimensions = {
  columns : int ;
  lines : int ;
}

/**
 * A location in a [Grid.t]
 *
 * Speeking as coordonates, we index [(column, line)],
 * with column and line starting from value [0], and getting
 * until [(Grid.dimensions.columns - 1, Grid.dimensions.lines - 1)]
**/

type Grid.column = int
type Grid.line = int

type Grid.location = {
  column : Grid.column ;
  line : Grid.line ;
}

/**
 * The type for manipulating a grid.
 * The dimensions are cached.
**/
@abstract
type Grid.t('content) = {
  dimensions : Grid.dimensions ;
  t : llarray(llarray('content)) ;
}

/**
 * Utils: For loop
**/
@public Loop = {{

  /**
   * [for(min, max, iter)] is equivalent to the imperative form
   * {[
   *   for i = min to max do
   *      iter(i);
   *   done
   * }
   * Note that the [max] value is also iterated.
  **/
  for(min, max, iter : int -> void) =
    rec aux(i) =
      if i > max then void else do iter(i) ; aux(succ(i))
    aux(min)

  /**
   * The first tuple is the bound of [i], the snd of [j],
   * and the function is the iteration.
   * [for((min, max), (min2, max2), iter)] is equivalent to the imperative form
   * {[
   *   for i = min to max do
   *     for j = min2 to max2 do
   *       iter(i, j);
   *     done
   *   done
   * }
  **/
  for2((min, max), (min2, max2), iter : int, int -> void) =
    for_i(i) =
      for(min2, max2, (j -> iter(i, j)))
    for(min, max, for_i)

  /**
   * Same than [for] for with an accumulator
  **/
  fold(min, max, fold : int, 'acc -> 'acc, acc) =
    rec aux(i, acc) =
      if i > max then acc else acc = fold(i, acc) ; aux(succ(i), acc)
    aux(min, acc)

  fold2((min, max), (min2, max2), f : int, int, 'acc -> 'acc, acc) =
    fold_i(i, acc) =
      fold(min2, max2, (j, acc -> f(i, j, acc)), acc)
    fold(min, max, fold_i, acc)
}}

/**
 * {1 Manipulation of the Grid}
**/

/**
 * Important note:
 * The module for manipulating the grid is available on both side, but
 * not necessary used.
 * In case we may want to have a side on each side, there would be no
 * serialization of the grid during the execution. (Multitub design)
 *
 * We could imagine serveral kind of clients, ligth or not.
 * E.g. a light client would not have the grid (only the server will),
 * where a heavyer client could before perform some checks locally before
 * sending action to the server which has anyway the grid for performance
 * and/or security reason.
**/
@both @public Grid = {{

  /**
   * Creating a new grid form [dimensions] and a default [content].
  **/
  make(dimensions : Grid.dimensions, content : 'content) : Grid.t =
    c = dimensions.columns
    l = dimensions.lines
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
   * Get the content of a location in the content of a grid.
   * Low level function, not exported.
   * @errors(Unspecified in case of index out of bounds)
  **/
  @private getij_t(t : llarray(llarray('content)), column : Grid.column, line : Grid.line) =
    t_line = LowLevelArray.get(t, column)
    content = LowLevelArray.get(t_line, line)
    content

  /**
   * Get the content of a location in a grid.
   * Interface usefull for loops.
   * @errors(Unspecified in case of index out of bounds)
  **/
  getij(grid : Grid.t, column : Grid.column, line : Grid.line) =
    t = grid.t
    getij_t(t, column, line)

  /**
   * Get the content of a location in a grid.
   * @errors(Unspecified in case of index out of bounds)
  **/
  get(grid : Grid.t, location : Grid.location) =
    getij(grid, location.column, location.line)

  /**
   * Set the content of a location.
   * The interface in functionnal because we may switch the current implementation
   * for a persistent implementation. But currently, the implementation in imperative.
   * @errors(Unspecified in case of index out of bounds)
  **/
  setij(grid : Grid.t('content), column : Grid.column, line : Grid.line, content : 'content) =
    t = grid.t
    t_line = LowLevelArray.get(t, column)
    do LowLevelArray.set(t_line, line, content)
    grid

  set(grid : Grid.t('content), location : Grid.location, content : 'content) =
    setij(grid, location.column, location.line, content)

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
      do Loop.for(0, pred(lines), iter)
      void
    do Loop.for(0, pred(columns), iter)
    grid

  /**
   * Fold. Column by column first, and inside, line by line.
  **/
  fold(fold, grid : Grid.t('content), acc : 'acc) =
    t = grid.t
    fold_line(line, acc) = LowLevelArray.fold(fold, line, acc)
    LowLevelArray.fold(fold_line, t, acc)

  /**
   * Fold neibourgh. Column by column, and inside, line by line.
   * The location itself is not folded.
   * The dist if the maximal distance separating 2 neibourghs.
  **/
  fold_neibourgh(fold, grid : Grid.t('content), location : Grid.location, dist : int, acc : 'acc) =
    dimensions = grid.dimensions
    columns = dimensions.columns
    lines = dimensions.lines
    grid_t = grid.t
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
            acc = fold(getij_t(grid_t, i, j), acc)
            aux(i, succ(j), acc)
    aux(min_c, min_l, acc)


   /**
    * iter on all locations of the Grid
   **/
   iterij(grid : Grid.t, iter) =
     dimensions = grid.dimensions
     columns = dimensions.columns
     lines = dimensions.lines
     Loop.for2((0, pred(columns)), (0, pred(lines)), iter)

   foldij(grid : Grid.t, fold, acc : 'acc) =
     dimensions = grid.dimensions
     columns = dimensions.columns
     lines = dimensions.lines
     Loop.fold2((0, pred(columns)), (0, pred(lines)), fold, acc)
}}

/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Interfaces for modules.
 * 
 * These interfaces are all what is needed to export for a good 
 * interaction between componants.
 *
 * Modules can have Internal Utils.
**/

/**
 * The type for manipulating array for representing the grid of the game.
 * An imperative implementation can also implements this interface
 * In this case, the returned grid is the same than the input grid.
 * Indexation is done in [[ 0 ; lines [[ * [[ 0 ; columns [[ 
**/

type Grid.SIG = {{
  dimensions : Grid.t('parameters, 'content) -> Grid.dimensions ;
  make : Grid.dimensions, 'parameters, 'content -> Grid.t('parameters, 'content) ;
  get : Grid.t('parameters, 'content), Grid.location -> 'content ;
  set : Grid.t('parameters, 'content), Grid.location, 'content -> Grid.t('parameters, 'content) ;
  get_parameters : Grid.t('parameters, 'content) -> 'parameters
  set_parameters : Grid.t('parameters, 'content), 'parameters -> Grid.t('parameters, 'content) ;
  clear : Grid.t('parameters, 'content), 'content -> Grid.t('parameters, 'content) ;
  fold : 'acc, ('acc, 'content -> 'acc), Grid.t('parameters, 'content) -> 'acc ;
  fold_neibourgh : 'acc, ('acc, 'content -> 'acc), Grid.t('parameters, 'content), Grid.location -> 'acc ;
}}

type GridUtils.SIG = {{
  differential : Grid.diffential, int -> int ;
}}

/**
 * Managment of Sets for IA.
 *
**/
type Set.SIG('elt) = {{
  inter : Set.t('elt), Set.t('elt) -> Set.t('elt) ;
  elements : Set.t('elt) -> list('elt) ;
  iter : ('elt -> void), Set.t('elt) -> void ;
  fold : 'acc, ('acc, 'elt -> 'acc), Set.t('elt) -> 'acc ;
  map : ('elt -> 'elt), Set.t('elt) -> Set.t('elt) ;

  /**
   * Print with syntax ["{ 1, 2, 3, 7 }"] e.g for int
  **/
  print: Set.t('elt) -> string ;

  /**
   * Folding intersection, but ignoring sets which
   * make the intersection become empty.
  **/
  priority_inter : list(Set.t('elt)) -> Set.t('elt) ; 

  /**
   * Pick a random elt in the set.
   * Returns { none } if the set is empty
  **/
  random : Set.t('elt) -> 'elt
}}

/**
 * Management of players and contents
 *
**/
type GameContent.SIG = {{

  equal : Game.content, Game.content -> Game.content ;

  /**
   * { free } < { 0 } < { X }
  **/
  compare : Game.content, Game.content -> int ;

  /**
   * Returns the negation of the Game.content.
   * The negation of { free } is { free }.
  **/
  neg_player : Game.player -> Game.player ;
  neg : Game.content -> Game.content ;

}}

/**
 * Utils for a Grid.grid(Game.content).
 * An implementation of this sig would be a functor
 * taking a Grid_SIG as argument
**/
type GameUtils.SIG = {{

 /**
   * Return the number of content present in the grid 
  **/			
  count : Game.grid, Game.content -> int ;

  /**
   * Check that the difference between player content.
   * {X} is by convention the first to play.
   * #{X}-1 <= #{0} <= #{X} 
  **/
  count_check : Game.grid -> bool ;

  /**
   * Say if a location is free
  **/
  free : Game.grid, Grid.location -> bool ;

  /**
   * Return the line index of the first free content
   * in a given column.
  **/
  free_line : Game.grid, Grid.column -> option(Grid.line) ;

  /**
   * Return the number of content of a kind in contact
   * with a given content
  **/
  count_contact : Game.grid, Game.content, Game.location -> int

  /**
   * Low level management of adding / removing contents, without
   * taking the gravity in consideration.
   * Not for casual user
  **/
  unsafe_add : Game.grid, Game.location, Game.content -> Game.grid

}}

type GameRules.SIG = {{

  /**
   * Returns the player which need to play.
   * As a convention, { X } is always the first
   * to play from an empty grid.
   * 
   * In case of incohrence, this will return
   * the player which has less pions in the grid.
  **/
  who_plays : Game.grid -> Game.player ;

  /**
   * Validate an action
  **/
  validate : Game.grid, Game.action -> bool ;

  /**
   * Compute possible actions.
   * In particular, If and only if the status is not 
   * { in_progress }, the set will be empty.
  **/
  actions : Game.grid -> Set.t(Game.action)

  /**
   * Determine the status of a grid
  **/
  status : Game.grid -> Game.status ;

}}

type Game.SIG = {{

  /**
   * Play an action in a grid.
   * Assertion : checks should have been done previously.
   * This is a precondition of the function
  **/
  play : Game.grid, Game.action -> Game.grid

  /**
   * Remove the last content played in a column.
   * Return the same grid if the column is empty.
  **/ 
  remove : Game.grid, Grid.column -> Game.grid

}}

type IA.SIG = {{

  /**
   * For simplicity, the IA is state less. 
   * It bring a lot of flexibility for this simple game.
   * The status of the grid should be { in_progress } or
   * this will raise an error.
  **/
  compute : Game.parameters, Game.grid -> Game.action ;

}}

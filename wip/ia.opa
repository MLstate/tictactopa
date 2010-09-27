/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

// TODO: split into ia_interfaces.opa & ia_implementation.opa

/**
 * IA for the tictactopa
**/

/**
 * {1 Private Types}
**/

/**
 * A potential is a consecutive range of location of size goal partially free 
 * or taken by the same player.
**/
type IA.potential_count = int

/**
 * We use a 2 dimension Grid for seing if a location make a player win
**/
type IA.winning_location = {
  X : bool ;
  O : bool ;
}

type IA.winning_grid = Grid.t(void, IA.winning_location)

/**
 * We need at some point to distinguish between odd and even locations
**/
type parity =  { even } / { odd }

type IA.winning_hint = {
  even : int ;
  odd : int ;
}

/**
 * {1 Utils}
**/

// TODO: the winning_grid can be used in a lot of points for preserving
// to compute several time the same things.
// Maybe: IA start with a IA.Stats and this is passed in each other functions

// + free positions
// + winning table
// + who_plays (status)

type IA.Winning.SIG = {{

  /**
   * Just so that compute_winning_grid can have an imperative
   * implementation for not reallocating a fresh winning_grid
  **/
  make_winning_grid : Grid.dimensions -> IA.winning_grid

  /**
   * Compute a winning table.
   * The interface is so that we can also use an imperative
   * implementation for the winning_grid.
  **/
  compute_winning_grid : Game.grid, IA.winning_grid -> IA.winning_grid

  /**
   * Count the number of winning location, odd and even.
   * It depends on the level of the IA. (use some more hint)
  **/
  compute_winning_hint : Game.grid, Game.player -> IA.winning_hint
}}


/**
 * {1 Strategies on actions}
 *
**/
// Strategy
// Maybe possible to make a functor to compute M.Force from M

type IA.ACTION.SIG = {{

  /**
   * If there is a final action for this player returns it
  **/
  find : Game.grid, Game.player -> option(Game.action)

  /**
   * Return the set of action so that the adversary does not
   * have a final action to play.
  **/
  anti : Game.grid -> Set.t(Game.action)
}}

/**
 * A forcing sequence is a succession of consecutive
 * actions leading to force the player to play something
**/

type IA.Final.SIG = IA.ACTION.SIG
type IA.Final.Force.SIG = IA.ACTION.SIG 

// bidon
// semi-bidon

type IA.FarAway.SIG = IA.ACTION.SIG
type IA.FarAway.Force.SIG = IA.ACTION.SIG

type IA.Strategic.SIG = IA.ACTION.SIG

// Probably too slow
// type IA.Strategic.Force.SIG = IA.ACTION.SIG

/**
 * {2 MinMax Metrics}
**/

/**
 * + Potential
 * + Germs
 * + Embryon
 * + Conjoint
**/

/**
 * {3 Metric 1 : Potential}
**/
type IA.Potential.SIG = {{

  /**
   * Count the potential traversing a location for a player of a certain
   * orientation.
  **/
  count_potential_location_orientation : 
    Game.grid, Game.player, Grid.location, Grid.orientation -> IA.potential_count ;

  /**
   * Same than [count_potential_orientation] but make the total for every
   * possible orientation (4 orientations)
  **/
  count_potential_column : 
    Grid.t, Game.player, Grid.column -> IA.potential_count ;

  /**
   * Returns the set of non zero potential columns
  **/
  columns_non_zero_potential_columns : Grid.t, Game.player -> Set.t(Grid.column)

  /**
   * Count the total of all potential of a given orientation
  **/
  count_potential_orientation :
    Game.grid, Game.player, Grid.orientation -> IA.potential_count ;

  /**
   * Same than [count_potential_orientation] but make the total for every
   * possible orientation (4 orientations)
  **/
  count_potential :
    Game.grid, Game.player -> IA.potential_count ;
  
  /**
   * In a set of actions, filter the actions with the maximal potential
  **/
  max :
    Game.grid, Set.t(Game.action) -> Set.t(Game.action)

  /**
   * In a set of actions, filter the actions with let the grid 
   * for the adversary with the minimal potential
  **/
  min :
    Game.grid, Set.t(Game.action) -> Set.t(Game.action)

}}



/**
 * {3 Metric 2 : Germs}
**/
// TODO: see if we can do a min max on germ instead of computing sets
// TODO: optimize, and take a set of action in input in order not
// to compute for action which are not in consideration.
type IA.Germ.SIG = {{

  /**
   * Compute the set of actions which introduces new germ in the game
   * Note: this use a diff between winning_hint, playing an action
  **/
  /** TODO: transform into max ? */
  compute_germ : Game.grid, IA.parity -> Set.t(Game.action) 

  /**
   * Compute the set of actions which make the adversary not
   * able to introduce new germ in the game
   * Note: this use a compute_germ internally
  **/
  /** TODO: transform into min ? */
  compute_no_germ : Game.grid, IA.parity -> Set.t(Game.action) 

  
}}

/**
 * {3 Metric 3 : Embryons}
**/
type IA.Embryon.SIG = {{

  /**
   * In a set of actions, filter the actions with the maximal embryon
  **/
  max :
    Game.grid, Set.t(Game.action) -> Set.t(Game.action)

// Too slow
//  /**
//   * In a set of actions, filter the actions with let the grid 
//   * for the adversary with the minimal embryon
//  **/
//  min :
//    Game.grid, Set.t(Game.action) -> Set.t(Game.action)
  
}}

/**
 * {3 Metric 4 : Conjoint}
**/
type IA.Conjoint.SIG = {{

  /**
   * Filter the actions with the maximum of conjoints
  **/
  max :
    Game.grid, Game.player, Set.t(Game.action) -> Set.t(Game.action)
}}

/** {1 Implementation} */

IAMinMax = @todo : IAMinMax.SIG

/**
 * The main function of the IA
**/

IA = {{

  compute(parameters, grid) = @todo

}} : IA.SIG

/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
 */

/**
 * Implementation of IA.
**/

/**
 * {1 Types}
**/

/**
 *
**/
type IA.parameters = {level : int}

/**
 * {1 Utils}
**/


/**
 * {1 Main IA module}
**/

/**
 * Actually, there are no reason to restrict the IA to the server side.
 * We can see what happen if the IA is on the client :)
**/

@both @public IA = {{

  Parameters = {{

    default = { level = 0 } : IA.parameters

  }}

  /**
   * Main function
   * For simplicity, the IA is state less.
   * It bring a lot of flexibility for this simple game.
   * The status of the grid should be { in_progress } or
   * this will raise an error.
   * Since this is stateless, we can by using it add an url
   * to the application for having a web service to play the tictactoe
  **/
  compute(game : Game.state) =
    player =
      match game.status with
      | { in_progress = player } -> player
      | _ -> @fail("IA.compute")
    grid = game.grid
    actions = GameRules.actions(grid)
    // First dummy version: play randomly
    action = ColSet.random(actions)
    action =
      match action with
      | {none} -> @fail("IA.compute: internal error")
      | {some = action} -> action
    action : Game.action

}}

/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
 */

/**
 * {0 Implementation of the server (Multitub design)}
**/

/**
 * {1 State}
**/

type S.implementation.state = {

  /**
   * The complete state of the game
  **/
  game : Game.state

  /**
   * The value may change each new game, choosen randomly.
  **/
  player : Game.player

  /**
   * A value for assuring the coherence of messages.
  **/
  date : Multitub.message.date
}

/**
 * {1 Utils}
**/

@server @package ServerUtils = {{

  /**
   * Choose randomly a player.
   * Used for knowing who will start.
   * The [GameParameters.first_player] is always the first to start,
   * and we choose randomly before each game, who is this player.
  **/
  choose_player(): Game.player =
    n = Random.int(2)
    player = if n == 0 then {Y} else {R}
    player

  /**
   * Generating a date for coherence of messages, because of the incertitude
   * concerning the order of emissions/receptions.
   * This is not about security, but just in case a mad monkey click
   * everywhere in the grid.
  **/
  generate_date(): Multitub.message.date =
    date = Random.int(max_int)
    date

  /**
   * Start a new game.
   * This function is used for initializing the first game of the connection,
   * as well as each time the client wants to restart a new game.
   * We can keep information in the game state from one game to on other,
   * using the function [Game.reset] which can preserve some informations.
   * We may add for example a victory counter.
  **/
  new_game(c_channel: Multitub.C.channel, state: S.implementation.state):S.implementation.state  =
    server_player = choose_player()
    client_player = GameContent.neg_player(server_player)
    server_starts =
      GameContent.equal_player(server_player, GameParameters.first_player)
    game = Game.reset(state.game)
    level = state.game.ia.level
    if server_starts
    then (
      do Multitub.send_client(c_channel, { who_you_are = client_player ; ~level ; date = none })
      action = IA.compute(game)
      match GameUtils.free_line(game.grid, action) with
      | {none} -> @fail("IA returns an illicit action")
      | {some = line} ->
        location = { column = action ; ~line }
        date = generate_date()
        do Multitub.send_client(c_channel, { player = server_player ; ~location ; date = some(date) })
        game = Game.play(game, action)
        { state with ~date ; ~game ; player = server_player }
    )
    else (
      date = generate_date()
      do Multitub.send_client(c_channel, { who_you_are = client_player ; ~level ; date = some(date) })
      { state with ~date ; ~game ; player = server_player }
    )

}}

/**
 * {1 Multitub Component}
**/

/**
 * Randomize, at toplevel, done once.
**/
// used to be: @server _ =
// when the bug is fixed (ie the compiler doesn't give an error with
// the previous line, it can be used)
@server _hack =
  do Random.random_init()
  void

@server Multitub_S : Multitub.S.interface(S.implementation.state) = {{

  /**
   * Initialization of the state.
  **/
  init() =
    game = Game.make()
    date = 0
    player = {Y}
    state = ~{ game date player }
    state : S.implementation.state

  /**
   * Extra initialization. Like starting a new game.
  **/
  on_connection(c_channel : Multitub.C.channel, state : S.implementation.state) =
    ServerUtils.new_game(c_channel, state)

  /**
   * Handler
  **/
  on_message(c_channel : Multitub.C.channel, state : S.implementation.state, message : Multitub.S.message) : Session.instruction(S.implementation.state) =
    match message with
    | { restart } ->
      state = ServerUtils.new_game(c_channel, state)
      { set = state }

    | { ia_parameters = ia } ->
      ia = IA.Parameters.check(ia)
      do jlog("server: setting level: {ia.level}")
      game = { state.game with ~ia }
      state = { state with ~game }
      { set = state }

    | ~{ action date } ->
      // Validate the date
      if date != state.date
      then
        // ignoring this request
        do jlog("ignoring the request, client-date:{date} server-date:{state.date}")
        {unchanged}
      else
        game = state.game
        // Validate the action
        match GameUtils.free_line(game.grid, action) with
        | {none} ->
          do Multitub.send_client(c_channel, {jlog = "You cannot play in {action} !"})
          {unchanged}
        | {some = line} ->
          // 1) confirmation for light clients
          client_player = GameContent.neg_player(state.player)
          location = { column = action ; ~line }
          do Multitub.send_client(c_channel, { player = client_player ; ~location ; date = none })
          // 2) updating the grid by playing the client token
          game = Game.play(game, action)
          // 3) depending on the status of the game, see what to do
          match game.status with
          | { ~winner } ->
            do Multitub.send_client(c_channel, { ~winner })
            state = { state with ~game }
            {set = state }

          | { in_progress = player } ->
            do @assert(GameContent.equal_player(state.player, player))
            action = IA.compute(game)
            // Validate the action of the IA
            match GameUtils.free_line(game.grid, action) with
            | {none} -> @fail("IA returns an illicit action")
            | {some = line} ->
              location = { column = action ; ~line }
              date = ServerUtils.generate_date()
              do Multitub.send_client(c_channel, { player = state.player ; ~location ; date = some(date) })
              game = Game.play(game, action)
              state = { state with ~game ~date }
              do match game.status with
                | { ~winner } ->
                  do Multitub.send_client(c_channel, { ~winner })
                  void
                | _ ->
                  void
              end
              { set = state }
            end

          | { incoherent } ->
            do jlog("Internal error, game incoherent")
            {unchanged}
          end
        end

}}

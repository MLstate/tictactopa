/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
 */

/**
 * {0 Implementation of the client (Multitub design)}
**/

/**
 * {1 State}
**/

/**
 * Note: An important part of the state of the client is in the DOM,
 * and manipulated via the module [ClientGrid]
**/

type C.implementation.state = {
  /**
   * Date are sent by the server for assuring coherence of messages
  **/
  date : Multitub.message.date

  /**
   * The player assigned to the client. Chosen by the server.
  **/
  player : Game.player

  /**
   * The advance is the difference between the number of token played
   * by the client and by the server. It is used to know if the client
   * can play.
  **/
  client_num : int
  server_num : int

  /**
   * A flag indicating if the game is over
  **/
  game_over : bool
}

/**
 * {1 Utils}
**/

@client @package ClientUtils = {{

  /**
   * This is a boolean which tell if this is the turn of the client.
  **/
  my_turn(state : C.implementation.state) =
    // do jlog("client_num:{state.client_num}")
    // do jlog("server_num:{state.server_num}")
    first_player = GameContent.equal_player(GameParameters.first_player, state.player)
    advance = state.client_num - state.server_num
    (advance < 0) || ((advance == 0) && first_player)

  /**
   * Display the status, depending on the state
  **/
  status(state) =
    if my_turn(state)
    then ClientLayout.set_status("YOUR TURN !")
    else ClientLayout.set_status("PLEASE WAIT...")
}}

/**
 * {1 Multitub}
 *
 * The instance (implementation) of the [Multitub.C] module.
 * Cf the documentation (and the example) of Multitub design pattern.
**/
@client Multitub_C : Multitub.C.interface(C.implementation.state) = {{

  /**
   * Initialization of the state.
  **/
  init() =
    client_num = 0
    server_num = 0
    date = 0
    player = {Y}
    game_over = false
    state = ~{ client_num server_num date player game_over }
    state : C.implementation.state

  /**
   * Handler.
   * Cf Multitub desig, the [s_channel] is used for sending messages to the server.
   * The [message] can come from the server, or from some funactions.
  **/
  on_message(s_channel : Multitub.S.channel, state : C.implementation.state, message : Multitub.C.message) : Session.instruction(C.implementation.state) =
    match message with
    | { jlog = message } ->
      do ClientLayout.jlog(message)
      {unchanged}

    | { who_you_are = player ; ~level ; ~date } ->
      do ClientLayout.set_level(level)
      do ClientLayout.set_player(player)
      do ClientGrid.clear()
      client_num = 0
      server_num = 0
      date = date ? state.date
      game_over = false
      state = ~{ state with client_num server_num player date game_over }
      do ClientUtils.status(state)
      {set = state}

    | { ~winner } ->
      match winner with
      | {none} ->
        do ClientLayout.set_status("EXAEQUO !")
        { set = { state with game_over=true} }
      | { some = player } ->
        do if GameContent.equal_player(player, state.player)
        then
          ClientLayout.set_status("YOU WIN :)")
        else
          ClientLayout.set_status("YOU LOOSE :(")
        { set = { state with game_over=true} }
      end
    | ~{ player location date } ->
        state =
          if GameContent.equal_player(player, state.player)
          then
            if GameContent.equal(ClientGrid.get_content(location), {free})
            then { state with client_num = state.client_num + 1 }
            else state // already added
          else { state with server_num = state.server_num + 1 }
      do ClientGrid.play(location, player)
      date = date ? state.date
      state = { state with ~date }
      do ClientUtils.status(state)
      {set = state}

    // The messages from the funactions
    | { ~funaction } ->
      match funaction with
      | { click = location } ->
        if not(ClientUtils.my_turn(state)) || state.game_over
        then {unchanged}
        else
          date = state.date
          state =
            match ClientGrid.free_line(location.column) with
            | { some = line } ->
              if line <= location.line
              then
                do ClientGrid.play({ location with ~line }, state.player)
                action = location.column
                do Multitub.send_server(s_channel, ~{action date})
                { state with client_num = state.client_num + 1 }
              else
                state
            | {none} ->
              state
            end
          {set = state}

      | { restart } ->
        do Multitub.send_server(s_channel, {restart})
        {unchanged}
      end
    end

  page = ClientLayout.page
}}

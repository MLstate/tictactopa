/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
 */

/**
 * Funactions of the Client User Interface.
**/

@client @package Funaction = {{

/**
 * The client has perform a click on the grid.
 * In this case, we pass through the client tube, and send to it the [click] message
 * No direct interaction with the server tube with this event.
**/
onclick_token(_ : Multitub.S.channel, c_channel : Multitub.C.channel, location : Grid.location, _) =
  do Multitub.send_client(c_channel, {funaction = { click = location } })
  void

/**
 * The client has perform a click on the "start a new game" button.
 * In this case, we pass through the client tube, and send to it the [restart] message
 * No direct interaction with the server tube with this event.
**/
restart(_ : Multitub.S.channel, c_channel : Multitub.C.channel, _) =
  do Multitub.send_client(c_channel, {funaction = {restart}})
  void

/**
 * The client has perform a click on the level toggle button.
 * In this case, we pass direclty through the server tube, and send to it the [ia_parameters] message
 * No direct interaction with the client tube with this event.
**/
level(s_channel : Multitub.S.channel, _ : Multitub.C.channel, dom_level : dom, _) =
  value = Dom.get_value(dom_level)
  level = int_of_string_unsafe(value)
  do Multitub.send_server(s_channel, {ia_parameters = { ~level }})
  void

}}

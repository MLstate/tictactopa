/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
 */

/**
 * Funactions of the Client User Interface.
**/

@client @package Funaction = {{

onclick_token(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel, location : Grid.location, _) =
  i = location.column
  j = location.line
  do Multitub.send_client(c_channel, {funaction = { click = location } })
  void

restart(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel, _) =
  do Multitub.send_client(c_channel, {funaction = {restart}})
  void

level(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel, dom_level : dom, _) =
  value = Dom.get_value(dom_level)
  level = int_of_string_unsafe(value)
  do Multitub.send_server(s_channel, {ia_parameters = { ~level }})
  void

}}

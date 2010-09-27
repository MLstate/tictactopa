/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Funactions of the Client User Interface.
**/

client Funaction = {{

onclick_token(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel, location : Grid.location, _) =
  i = location.column
  j = location.line
  do jlog("Your click : {i},{j}")
  do exec( [ #status <- "Your click : {i}{j}" ])
  color=(if mod(i+j, 2) == 0 then {Y} else {R})
  do
    match ClientToken.get_content(location) with
    | {free} -> ClientToken.set_content(location, {R})
    | {R} -> ClientToken.set_content(location, {Y})
    | {Y} -> ClientToken.set_content(location, {free})
  void

}}

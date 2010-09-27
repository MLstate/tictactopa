/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Client User Interface.
**/

/**
 * {1 Token}
**/

/**
 * There are 2 colors of token, red and yellow.
 * @private
**/
type ClientToken.color = string

/**
 * A type for manipulating token via jQuery API
 * @abstract
**/
type ClientToken.t = jquery


/**
 * The module to manipulate Tokens
**/
client ClientToken = {{

/**
 * {1 Position}
**/

/**
 * Sadly, the grid and the token are not regular
 * A aproximantion is :
 * line
 * y = global_margin + margin_y_token + (6 - line) * box_token
 * column
 * x = global_margin + margin_x_token + (column - 1) * box_token
 * But this does not fit perfectly in the resource/grid.png
 * This simple switch is efficient, and simple.
**/

/**
 * From the column of the token, get the absolute position from the left side
 * of the browser where to put the token, so that it fits perfectly in the grid.
 * A match failure would be an internal error, will get the trace in that case.
**/
absolute_column_position =
  | 0 -> 44
  | 1 -> 140
  | 2 -> 237
  | 3 -> 334
  | 4 -> 430
  | 5 -> 527
  | 6 -> 624

/**
 * From the line of the token, get the absolute position from the top side
 * of the browser where to put the token, so that it fits perfectly in the grid.
 * A match failure would be an internal error, will get the trace in that case.
**/
absolute_line_position =
  | 0 -> 527
  | 1 -> 430
  | 2 -> 332
  | 3 -> 235
  | 4 -> 136
  | 5 -> 39

/**
 * {1 Layout}
**/

/**
 * Convention for the DOM id
**/
id(location : Grid.location) =
  i = location.column
  j = location.line
  id = "token{i}{j}"
  id

/**
 * Get the token from its location
**/
token(location : Grid.location) =
  unarySharp(id(location)) : ClientToken.t

/**
 * Get the 'style' property of a token from its location.
**/
style(location : Grid.location) =
  left = absolute_column_position(location.column)
  top = absolute_line_position(location.line)
  css { left:{left}px; top:{top}px; }

/**
 * For drawing token, we use css classes.
 * The class 'token' will assure the correct position to the token,
 * where the classes 'red' and 'yellow' will assure the correct coloration.
**/

/**
 * Bind the type Game.player with a corresponding color.
**/
color_of_player(player : Game.player) =
  match player with
  | {Y} -> "yellow"
  | {R} -> "red"

player_of_color(color : ClientToken.color) =
  match color with
  | "yellow" -> {Y}
  | "red" -> {R}

/**
 * Clear a token, meaning remove all color classes from it.
**/
clear(token : ClientToken.t) =
  do jQuery.removeClass("red yellow", token)
  void

/**
 * Colorize a token, meaning applying the corresponding class to it.
**/
colorize(token : ClientToken.t, color) =
  do clear(token)
  do jQuery.addClass(color, token)
  void

/**
 * Same as colorize, but binded with the type Grid.*, Game.*
**/
play(location : Grid.location, player : Game.player) =
  color = color_of_player(player)
  token = token(location)
  colorize(token, color)

/**
 * From the content
**/
set_content(location : Grid.location, content : Game.content) =
  token = token(location)
  match content with
  | {free} -> clear(token)
  | _ ->
    player = Game.player_of_content(content)
    color = color_of_player(player)
    colorize(token, color)

get_content(location : Grid.location) =
  token = token(location)
  content =
    if jQuery.hasClass("red", token)
    then player_of_color("red")
    else
      if jQuery.hasClass("yellow", token)
      then player_of_color("yellow")
      else {free}
  content : Game.content

/**
 * Build the xhtml of a token, depending on its location.
 * CF multitub design, the Client has access to the 2 session for building the page,
 * and funactions may take them in argument.
**/
xhtml(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel, location : Grid.location) =
  id = id(location)
  <>
    <div
      id="{id}"
      class={["token"]}
      style={style(location)}
      onclick={Funaction.onclick_token(s_channel, c_channel, location, _)}
    />
  </>

}}


ClientGrid = {{

/**
 * Build the xhtml of the grid.
 * CF multitub design, the Client has access to the 2 session for building the page,
 * and funactions may take them in argument.
**/
xhtml(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel) =
  rec aux(acc, i, j) =
    if i > 6 then acc
    else
     if j > 5 then aux(acc, i+1, 0)
     else
       location = { column = i ; line = j }
       acc=
         <>
           {acc}
           {ClientToken.xhtml(s_channel, c_channel, location)}
         </>
      aux(acc, i, j+1)
  <>
    <div id="grid">
      {aux(<></>, 0, 0)}
    </div>
  </>

}}

client ClientLayout = {{

/**
 * Build the complete page
**/
page(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel) =
  xhtml =
    <>
      {ClientGrid.xhtml(s_channel, c_channel)}
      <div id="status"/>
    </>
  xhtml

}}

/**
 * {1 CSS}
**/

css = css
.token{
  position:absolute;
  width: 83px;
  height: 83px;
}
.red{
  background-image:url('/resources/red.png');
  background-repeat:no-repeat;
}
.yellow{
  background-image:url('/resources/yellow.png');
  background-repeat:no-repeat;
}
#grid{
  margin:20px;
  width:692px;
  height:600px;
  background-image:url('/resources/grid.png');
  background-repeat:no-repeat;
  float:left;
}

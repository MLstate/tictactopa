/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
**/

/**
 * {0 Client Web, User Interface}
**/

/**
 * {1 Types}
**/

/**
 * There are 2 colors of token, red and yellow.
 * @private
**/
type ClientToken.color = string

/**
 * A type for manipulating tokens (via Dom API)
 * @abstract
**/
type ClientToken.t = dom

/**
 * {1 Tokens}
**/

/**
 * The module to manipulate Tokens
**/
@client @public ClientToken = {{

/**
 * {1 Position}
**/

/**
 * Sadly, the images used for the grid and the token are not regular
 * A aproximantion is :
 * line
 * y = global_margin + margin_y_token + (6 - line) * box_token
 * column
 * x = global_margin + margin_x_token + (column - 1) * box_token
 * But this does not fit perfectly in the resource/grid.png
 * The 2 following simple switches are efficient, and simple.
**/

/**
 * From the column of the token, get the absolute position from the left side
 * of the browser where to put the token, so that it fits perfectly in the grid.
 * A match failure would be an internal error, we can get the trace in that case.
**/
@private absolute_column_position =
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
 * A match failure would be an internal error, we can get the trace in that case.
**/
@private absolute_line_position =
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
 * Convention for the DOM id.
**/
@private id(location : Grid.location) =
  i = location.column
  j = location.line
  id = "token{i}{j}"
  id

/**
 * Get the token from its location.
 * All token are accessible from their position.
**/
token(location : Grid.location) =
  unarySharp(id(location)) : ClientToken.t

/**
 * Get the 'style' property of a token from its location.
 * This is private, because this module centralize the creation
 * of all token DOM elements.
**/
@private style(location : Grid.location) =
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
@private color_of_player(player : Game.player) =
  match player with
  | {Y} -> "yellow"
  | {R} -> "red"

@private player_of_color(color : ClientToken.color) =
  match color with
  | "yellow" -> {Y}
  | "red" -> {R}

/**
 * Clear a token, which means : remove all its color classes.
 * The token will no longer be visible.
**/
clear(token : ClientToken.t) =
  _ = Dom.remove_class(token, "red yellow")
  void

/**
 * Colorize a token, meaning applying the corresponding class to it.
**/
colorize(token : ClientToken.t, player : Game.player) =
  color = color_of_player(player)
  do clear(token)
  _ = Dom.add_class(token, color)
  void

/**
 * Get the content of a token.
 * A higher level API is given in the module [ClientGrid] for accessing
 * the content from the position.
**/
content(token : ClientToken.t) =
  content =
    if Dom.has_class( token, "red")
    then player_of_color("red")
    else
      if Dom.has_class(token, "yellow")
      then player_of_color("yellow")
      else {free}
  content : Game.content

/**
 * Build the xhtml of a token of the grid, depending on its location.
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

/**
 * Make some more token.
 * This is used for building token which are not on the grid.
 * Typically, we use it for building the token which show the color
 * assigned to the client during the game.
**/
make(name : string) =
  unarySharp(name) : ClientToken.t

}}

/**
 * {1 Client Grid}
**/

@client ClientGrid = {{

/**
 * Same as [ClientToken.colorize], but binded with the type Grid.*, Game.*
**/
play(location : Grid.location, player : Game.player) =
  token = ClientToken.token(location)
  ClientToken.colorize(token, player)

/**
 * From the content
**/
set_content(location : Grid.location, content : Game.content) =
  token = ClientToken.token(location)
  match content with
  | {free} -> ClientToken.clear(token)
  | _ ->
    player = FixTheTyper.player_of_content(content)
    ClientToken.colorize(token, player)

get_content(location : Grid.location) =
  token = ClientToken.token(location)
  ClientToken.content(token)

/**
 * Optimization: for the reactivity of the click, we can update the client grid before
 * receiving the confirmation of the server, and even skip bad user proposition in case
 * of a illegal click. We just need a function which say if the place is free.
 * Returns the first free line of a given column (starting from the bottom)
**/
free_line(column : Grid.column) =
  lines = GameParameters.dimensions.lines
  free(location) =
    content = get_content(location)
    GameContent.equal(content, {free})
  rec aux(line) =
    if line >= lines then none
    else
      location = ~{ column line }
      if free(location) then some(line)
      else aux(succ(line))
  aux(0)

/**
 * Clear all the grid, restarting a fresh game.
**/
clear() =
  clear_token(i, j) =
    location = { column = i ; line = j }
    token = ClientToken.token(location)
    do ClientToken.clear(token)
    void
  do Loop.for2((0, GameParameters.dimensions.columns - 1), (0, GameParameters.dimensions.lines - 1), clear_token)
  void

/**
 * Build the xhtml of the grid.
 * CF multitub design, the Client has access to the 2 sessions for building the page,
 * and funactions may take them in argument.
**/
xhtml(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel) =
  rec aux(acc, i, j) =
    if i >= GameParameters.dimensions.columns then acc
    else
     if j >= GameParameters.dimensions.lines then aux(acc, i+1, 0)
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

/**
 * {1 Layout}
**/

@client ClientLayout = {{

  /**
   * The id of the status DOM element
  **/
  @private status_id = "status"

  /**
   * The id of the restart DOM element
  **/
  @private restart_id = "restart"

  /**
   * The id of the token showing your color
  **/
  @private player_id = "player"

  /**
   * The id of the level selection
  **/
  @private level_id = "level"

  /**
   * Build the complete page.
   * <!> FIXME: this function cannot comport any jlog, it cause a looping initialization.
  **/
  page(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel) =
    xhtml =
      <>
        {ClientGrid.xhtml(s_channel, c_channel)}
        <br/>
        <div>
          Your token color for this game : <div id="{player_id}" class={["yourtoken"]} />
        </div>
        <div id="{status_id}"></div>
        <select id="{level_id}" onchange={Funaction.level(s_channel, c_channel, unarySharp(level_id), _)}>
          <option value=0 selected>level:random</option>
          <option value=1>level:dummy</option>
          <option value=2>level:novice</option>
          <option value=3>level:advanced</option>
          <option value=4>level:expert</option>
        </select>
        <div>
          <a id="{restart_id}" class="button" href="#" onclick={Funaction.restart(s_channel, c_channel,_)}>Start a new game</a>
        </div>
      </>
    xhtml

  /**
   * Log something from the server
  **/
  jlog(message) =
    do jlog("Message from the server : {message}")
    void

  /**
   * Draw in the User Interface the player
  **/
  set_player(player) =
    player_token = ClientToken.make(player_id)
    ClientToken.colorize(player_token, player)

  /**
   * Write in the User Interface the status
  **/
  set_status(status : string) =
    do exec_actions([ #{status_id} <- status ])
    void
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
.yourtoken{
  position:absolute;
  left:820px;
  top:100px;
  width: 83px;
  height: 83px;
}
#status{
  position:absolute;
  left:810px;
  top:300px;
}
#level{
  position:absolute;
  left:800px;
  top:450px;
}
#restart{
  position:absolute;
  left:790px;
  top:600px;
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

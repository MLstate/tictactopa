/*
 * Tictactopa. (c) MLstate - 2011
 * @author Mathieu Barbin
**/

/**
 * This is a test program to show the client manipulation
 * of the game grid. It contains the global properties for
 * setting the grid, and uses the resources of the game.
 */

// global_margin = 20
// size_token = 83
// box_token=97
// margin_x_token = 24
// margin_y_token = 21

// The grid and the token are not regular
// A aproximantion is :
// line
// y = global_margin + margin_y_token + (6 - line) * box_token
// column
// x = global_margin + margin_x_token + (column - 1) * box_token
// But this fits better so :

absolute_token_x =
  | 1 -> 44
  | 2 -> 140
  | 3 -> 237
  | 4 -> 334
  | 5 -> 430
  | 6 -> 527
  | 7 -> 624

absolute_token_y =
  | 1 -> 527
  | 2 -> 430
  | 3 -> 332
  | 4 -> 235
  | 5 -> 136
  | 6 -> 39

token_style(column, line) =
  x = absolute_token_x(column)
  y = absolute_token_y(line)
  css { left:{x}px; top:{y}px; }

token_class(color) =
  color =
    match color with
    | { red } -> "red"
    | { yellow } -> "yellow"
  "token {color}"

token_html(i, j, color) =
  <div
    id="token{i}{j}"
    class={[token_class(color)]}
    style={token_style(i, j)}
  >
  </div>

onclick_token(i, j) =
  do jlog("Your click : {i},{j}")
  do exec( [ #status <- "Your click : {i}{j}" ])
  color=(if mod(i+j, 2) == 0 then { yellow } else { red })
  token = Dom.select_id("token{i}{j}")
  do if Dom.has_class( token, "red") || Dom.has_class(token, "yellow")
  then
    Dom.remove_class(token, "red yellow")
  else
    Dom.add_class(token, token_class(color))
  void

all() =
  rec aux(acc, i, j) =
    if i > 7 then acc
    else
     if j > 6 then aux(acc, i+1, 1)
     else
       color=(if mod(i+j, 2) == 0 then { yellow } else { red })
       acc=
         <>
         {acc}
         <div id="place{i}{j}" onclick={_->onclick_token(i, j)}>{token_html(i, j, color)}</div>
         </>
      aux(acc, i, j+1)
  aux(<></>, 1, 1)

tictactopa() =
do jlog("done once on the server")
xhtml=
<>
  <div id="grid">

  {all()}

  </div>
  <div id="status"></div>
</>
html("tictactopa", xhtml)

png(png) = Resource.image({png=png})

urls = parser
  | "/grid.png" -> png(@static_source_content("./resources/grid.png"))
  | "/red.png" -> png(@static_source_content("./resources/red.png"))
  | "/yellow.png" -> png(@static_source_content("./resources/yellow.png"))
  | (.*) -> tictactopa()

server = simple_server(urls)

css = css
.token{
  position:absolute;
  width: 83px;
  height: 83px;
}
.red{
  background-image:url('/red.png');
  background-repeat:no-repeat;
}
.yellow{
  background-image:url('/yellow.png');
  background-repeat:no-repeat;
}
#grid{
  margin:20px;
  width:692px;
  height:600px;
  background-image:url('/grid.png');
  background-repeat:no-repeat;
  float:left;
}

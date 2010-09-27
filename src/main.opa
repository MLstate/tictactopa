/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Urls and server definition.
**/

png(png) = Resource.image({png=png})

urls = parser
  | "/resources/grid.png"   -> png(@static_source_content("./resources/grid.png"))
  | "/resources/red.png"    -> png(@static_source_content("./resources/red.png"))
  | "/resources/yellow.png" -> png(@static_source_content("./resources/yellow.png"))
  | (.*) -> Multitub.resource("tictactopa")

server = simple_server(urls)

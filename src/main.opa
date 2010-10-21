/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * {1 Urls and server definition.}
**/

/**
 * By default, all URLs are dispatched to the multitub.
 */
urls      = parser .* -> _ -> Multitub.resource("tictactopa")

/**
 * Use the resources in directory resources/
 */
resources = @static_include_directory("resources")

/**
 * Start the server, using both [urls] and [resources]
 */
server    = Server.make(Resource.add_auto_server(resources, urls))

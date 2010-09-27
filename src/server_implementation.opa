/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Implementation of the server (Multitub design).
**/

type S.implementation.state = { todo }

server Multitub_S : Multitub.S.interface(S.implementation.state) = {{

  /**
   * Initialization of the state.
  **/
  init() =
    { todo } : S.implementation.state

  /**
   * Handler
  **/
  on_message(c_channel : Multitub.C.channel, state : S.implementation.state, message : Multitub.S.message) =
    {unchanged}

}}

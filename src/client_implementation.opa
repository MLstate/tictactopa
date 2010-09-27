/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * Implementation of the client (Multitub design).
**/

type C.implementation.state = { todo }

client Multitub_C : Multitub.C.interface(C.implementation.state) = {{

  /**
   * Initialization of the state.
  **/
  init() =
    { todo } : C.implementation.state

  /**
   * Handler
  **/
  on_message(s_channel : Multitub.S.channel, state : C.implementation.state, message : Multitub.C.message) =
     {unchanged}

  page = ClientLayout.page
}}

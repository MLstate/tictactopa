/**
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * This is just a prototype to see how session are dispatched between
 * the client and the server.
 *
 * In this design, there is a session on the server for each client,
 * and a session on the client.
 *
 * The server session is not allowed to have access to the dom,
 * it is just allowed to send messages to the associated client session.
 */

/**
 * {1 Events}
 * Public contract : just the interface of messages (event)
 */

/**
 * {2 Server}
 */

/**
 * + {a} : a first message, without argument
 * + {b:int} : a message interracting with the state of the server
 */
type S.message = { a } / { b : int }

type S.channel = channel(S.message)

/**
 * {2 Client}
 */

/**
 * In this prototype, only 1 message, a value from the server.
 */
type C.message = { value : int }

type C.channel = channel(C.message)

/**
 * {1 Handler, components}
 */

/**
 * Once this contract is established, handler on the 2 sides are independant,
 * and can be switched. We could imagine have serveral implementation of (init, handler)
 * with the corresponding type of message.
 */

/**
 * {2 Server}
 */

type S.ARG.interface('state) = {{
  init : void -> 'state
  on_message : C.channel, 'state, S.message -> Session.instruction('state)
}}

/**
 * {2 Client}
 */

type C.ARG.interface('state) = {{
  init : void -> 'state
  on_message : S.channel, 'state, C.message -> Session.instruction('state)
}}

/**
 * {1 Functorisation}
 */

type S.M.state('state) = {
  client : option(C.channel)
  state : 'state
}

type S.M.message = { message = S.message } / { set_client : C.channel }

session_map_instruction(map, i) =
  match i : Session.instruction with
  | {set = state} -> {set = map(state)}
  | {unchanged}
  | {stop} -> Magic.id(i) : Session.instruction // Fixme: do something with the typer

M(C : C.ARG.interface('c_state), S : S.ARG.interface('s_state)) = {{
  c_init(server) =
    state = C.init()
    ~{ server state }

  c_on_message(state, message) =
    map(internal_state) = { state with state = internal_state }
    session_map_instruction(map, C.on_message(state.server, state.state, message))

  s_init() =
    state = S.init()
    {client = {none} ; ~state} : S.M.state('s_state)

  s_on_message(state, message) =
    match message with
    | { set_client = channel } ->
      { set = { state with client = { some = channel } } }
    | { ~message } -> (
      match state.client with
      | {none} -> error "Internal error, the client has not been set yet"
      | {some = client} ->
        map(internal_state) = { state with state = internal_state }
        session_map_instruction(map, S.on_message(client, state.state, message))
    )

  client c_onload(s_channel, _) =
    c_channel = Session.make(c_init(server), c_on_message)
    do send(server, {set_client = c_channel})
    exec_actions( [ #main <- C.page(s_channel, c_channel) ] )
    void

  server page() =
    server = Session.make(s_init(), s_on_message)
    <>
      <div id="main" onready={c_onload(server, _)}>
        "default page (not yet set by the client)"
      </div>
    </>

  server one_page_server(name) = one_page_server(name, page)
}}

/**
 * {1 Instance}
 *
 * Example of an instance for this design.
 */

/**
 * {2 Server S1}
 */

type S1.state = { value : int }

S1 : S.ARG.interface(S1.state) = {{
  init() =
    { value = 0 } : S1.state

  on_message(state : S.state(S1.state), message : S.message) =
    match message with
    | { a } ->
      do jlog("Receive: message A, will update my state, and the dom")
      do send(state.client, {value = state.value})
//      do exec_actions([ #response <- <>The state of the server is : {state.state}</>])
//      do response(state)
      {unchanged}
    | { b = int } ->
      do jlog("Receive: message B ({int}), will update my value, and the dom")
      value = { value = int }
      do send(state.client, {~value})
//      do exec_actions([ #response <- <>The state of the server is : {state.state}</>])
//      do response(state)
      { set = value }
}}

/**
 * {2 Client C1}
 */

/**
 * For example, the client wants to keep the number of {a} messages sent to the server.
 */

type C1.state = { num_a : int }

C1 : C.ARG.interface(C1.state) = {{
  init() =
    { num_a = 0 } : C1.state

  on_message(state : C.state(C1.state), message : C.message) =
    match message with
    | { ~value } ->
      do exec_actions([ #response <- <>The value of the server is : {value}</>])
}}

client response(state) =
  match state with
  | { ~state } ->




messageA(s, _) =
  send(s, {a})

messageB(s, i, _) =
  send(s, {b=i})

// client make_client_session() =
//   Session.make(C.init(), C.handler)

@expand button(id,message,action)=
  <a id={id:string} class="button" href="#" onclick={action}>{message:string}</a>

proto() =
  proto = Session.make(S.init(), S.handler)
//  protoC = make_client_session()
  <>
    <h2>Response of the server</h2>
    <div id="response"/>
    <h2>Send messages to the server</h2>
    <a id={"messageA"} class="button" href="#" onclick={messageA(proto, _)}>{"Message A"}</a>
    <a id={"messageB0"} class="button" href="#" onclick={messageB(proto, 0, _)}>{"Message B(0)"}</a>
    // {button("messageA", "Message A", messageA(proto, _))}<br/>
    // {button("messageB0", "Message B(0)", messageB(proto, 0, _))}<br/>
    {button("messageB1", "Message B(1)", messageB(proto, 1, _))}<br/>
    {button("messageB2", "Message B(2)", messageB(proto, 2, _))}<br/>

  </>

server = one_page_server("Proto", proto)

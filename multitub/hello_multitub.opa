/**
 * OPA design pattern collection. (c) MLstate - 2010
 *
 * The Mutlitub pattern, for OPA-S3.
 * @author Mathieu Barbin
 */

/**
 * A simple example using the multitub pattern.
 */

/**
 * {1 Messages}
 */

/**
 * {2 Server}
 */

/**
 * + {a} : a first message, without argument
 * + {b:int} : a message interracting with the state of the server
 */
type Multitub.S.message = { a } / { b : int }


/**
 * {2 Client}
 */

/**
 * + {value:int} a value from the server.
 * + {funaction} an event indicating that we want to send a message {a} to the server.
 */
type Multitub.C.message = { value : int } / { funaction }


/**
 * {1 Handler, components}
 */

/**
 * {2 Server S1}
 */

type S1.state = { value : int }

server Multitub_S : Multitub.S.interface(S1.state) = {{
  init() =
    { value = 0 } : S1.state

  on_message(c_channel : Multitub.C.channel, state : S1.state, message : Multitub.S.message) =
    match message with
    | { a } ->
      do jlog("Receive: message A, send my state to the client.")
      do Multitub.send_client(c_channel, {value = state.value})
      {unchanged}
    | { b = int } ->
      do jlog("Receive: message B ({int}), will update my value, and the dom")
      value = { value = int }
      do Multitub.send_client(c_channel, value)
      { set = value }
}}

/**
 * {2 Client C1}
 */

/**
 * For example, the client wants to keep the number of {a} messages sent to the server.
 */
type C1.state = { num_a : int }

/**
 * Example of a funaction sending directly a message to the server.
 */

client messageB(s_channel, i, _) =
  Multitub.send_server(s_channel, {b=i})

/**
 * Example of a funaction which use the client session
 */
client messageA(c_channel, _) =
  Multitub.send_client(c_channel, {funaction})

client page(s_channel : Multitub.S.channel, c_channel : Multitub.C.channel) =
  <>
    <h2>Response of the server</h2>
    <div id="response"/>
    <h2>Number of message A</h2>
    <div id="messageA_counter"/>
    <h2>Send messages to the server</h2>
    <a id={"messageA"} class="button" href="#" onclick={messageA(c_channel, _)}>{"Message A"}</a>
    <a id={"messageB0"} class="button" href="#" onclick={messageB(s_channel, 0, _)}>{"Message B(0)"}</a>
    <a id={"messageB1"} class="button" href="#" onclick={messageB(s_channel, 1, _)}>{"Message B(1)"}</a>
    <a id={"messageB2"} class="button" href="#" onclick={messageB(s_channel, 2, _)}>{"Message B(2)"}</a>
    <a id={"messageB3"} class="button" href="#" onclick={messageB(s_channel, 3, _)}>{"Message B(3)"}</a>
  </>

client Multitub_C : Multitub.C.interface(C1.state) = {{
  init() =
    { num_a = 0 } : C1.state

  on_message(s_channel : Multitub.S.channel, state : C1.state, message : Multitub.C.message) =
    match message with
    | { ~value } ->
      do jlog("Receive: message value, update the DOM")
      do exec_actions([ #response <- <>The value of the server is : {value}</>])
      {unchanged}
    | {funaction} ->
      do jlog("Receive: message funaction, update the DOM, and send")
      num_a = state.num_a + 1
      do exec_actions([ #messageA_counter <- <>Number of A messages sent : {num_a}</>])
      do Multitub.send_server(s_channel, {a})
      {set = {~num_a}}

  page = @toplevel.page
}}


/**
 * Server.
 */
server = Multitub.one_page_server("Hello Multitub")

/*
 * Tictactopa. (c) MLstate - 2010
 * @author Mathieu Barbin
**/

/**
 * {0 Messages definition (Multitub design)}
**/

/**
 * This is part of the Multitub design, this file defines all the event the 2 sides
 * can handle. That is the definition of a contract.
**/

/**
 * {1 Some Explanations about the Scenario}
**/

/**
 * In the beginnging of a game, the server will randomly choose who does begin, and
 * send the message { who_you_are } to the client.
 * Waiting for this message, the client should not start to send anything.
 * (the messages will be ignored)
 * Light client can simply ignore the value of the player.
 * Any client receiving this message should clear the grid.
 *
 * After that, as we want to deal with light clients, the server can receive lots
 * of action, but will check that the date of the message correspond to the uniq
 * id it has generated. Any other message of action will just be ignored.
 *
 * Each time the client whish to play, it send the message {action} to the server,
 * with the correct date the server responds by some action too.
 * One moment, the server will also tell the client that the game is over,
 * the client can choose to wait so that the user can see the resulting game,
 * and decide in an other moment to restart a new game.
**/

import tictactopa.{colset,grid,game}

/**
 * {1 Common Types}
**/

/**
 * This type is meant to control that messages received from the client are not outdated.
 * e.g if the server takes too much time to compute its action, the client may already click
 * everywhere and send a lot of messages. We should just ignore them if there are outdated.
 * May be unused, let's see what happen.
**/
type Multitub.message.date = int

/**
 * {1 Server}
 *
 * All the messages the server must handle.
 * They come all from a client.
 * This type of messages is handled by the funtion [on_message] of the server implementation.
**/

type Multitub.S.message =
   /**
    * The client whish to restart a new game.
    * This will reset the game state of the server.
   **/
   { restart }

   /**
    * The client wants to change the parameters of the IA.
    * The type IA.parameters is defined on both side.
   **/
 / { ia_parameters : IA.parameters }

   /**
    * The client has choosen where to play, and it notifies the server.
    * There will be 2 answers, the confirmation to add the token of the client,
    * and later the response of the server.
   **/
 / { action : Game.action ; date : Multitub.message.date }


/**
 * {1 Client}
 *
 * All the messages a client must handle.
 * Some of them come from the server, some other come from some funaction after a user event
 * like a click, mouse event, etc.
 *
 * Maybe: parametrize the type Multitub.C.message by the message received from the funactions ?
**/

type Multitub.C.funaction =
   /**
    * The user has done a click on the grid
   **/
   { click : Grid.location }

   /**
    * The user wants to restart a new game
   **/
 / { restart }

type Multitub.C.message =
   /**
    * In case the server wants to jlog something on the client side.
   **/
   { jlog : string }

   /**
    * The server has assigned a player to the client, randomly for each game.
    * If the server should start, the date is not given, so that every action
    * sent to the server before it has had the time to play would be ignored.
   **/
 / { who_you_are : Game.player ; date : option(Multitub.message.date) }

   /**
    * The server wants to notify the client that the game is over.
    * Somebody should have won, or the match is exaeco.
   **/
 / { winner : Game.winner }

   /**
    * The server notify the client that somebody has played somewhere.
    * The client should modify the DOM consistently.
    * The client is authorized to optimize its behavior, by already displaying the token
    * that the user has played, before that the server confirm its location, but the client
    * should then ignore without errors the message of confirmation from the server.
    * The server does not know if the client is heavy or light (typically, if the client
    * has a internal representation of the game state) so the server will send the message
    * to add the token of the client anyway, in addition to the message for playing back.
    *
    * There are 2 forms for this message. With or without the date. The one with the date
    * is the response of the server. The client should use the same date in its next action
    * if not, the server will ignore it.
   **/
 / { player : Game.player ; location : Grid.location ; date : option(Multitub.message.date) }

   /**
    *
   **/
 / { funaction : Multitub.C.funaction }

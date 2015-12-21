# NAME

Bot::ClueBot::Plugin::WebSocket - ClueBot plugin that provides a websocket interface to the bot's features

# VERSION

Version 0.02

# SYNOPSIS

When enabled, this plugin will listen for websocket connections to a given port (defaults to 9191),
through which you can execute commands on the bot.

You can connect ot the websocket interface using an endpoint url like `ws://hostname:port/$user/$token`.

The token can be requested by users from the WebToken plugin.

You can use the test script `cluebot-websocket-client` for test purposes:

    ./cluebot-websocker-client ws://my-jabber-server:9191/user@domain/eyJhbGciOi...
    Connected!
    Received message from endpoint:
        {"text":"Welcome, user@domain/ws0!"}
    {"command":"help", "params":{"command":"web_token"}}
    Sending {"command":"help", "params":{"command":"web_token"}}...
    Received message from endpoint:
        {"response":"Help for web_token:\nGenerate auth token for use with other bot services","seq":0}
    {"command":"list_chatrooms"}
    Sending {"command":"list_chatrooms"}...
    Received message from endpoint:
        {"response":{"testbot_log@conference.domain":{"autojoin":"1","password":null,"quiet":"0"}},"seq":1}

# OPTIONS

- port

    Port on which to listen for connections. Defaults to 9191.

# HELPERS

- ws\_connection( $user )

    Returns any websocket connections by the given user.

- ws\_send( $user, $data )

    Send a message to the user via webssocket.

# COMMANDS

- websocket\_status

    Reports all currently open websocket connections

# NAME

Bot::ClueBot::Plugin::WebSocket - ClueBot plugin that provides a websocket interface to the bot's features

# VERSION

Version 0.02

# SYNOPSIS

When enabled, this plugin will listen for websocket connections to a given port (defaults to 9191),
through which you can execute commands on the bot.

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

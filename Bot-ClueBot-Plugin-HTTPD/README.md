# NAME

Bot::ClueBot::Plugin::HTTPD - ClueBot plugin that provides HTTP access to the bot

# VERSION

Version 0.02

# SYNOPSIS

When this plugin is enabled, the bot will listen for HTTP connections on a given
port (defaults to 9090), providing access to bot features.

In order to authenticate the user, a JWT is required, which can be requested via
the WebTokens plugin.

While plugins can register additional url endpoints, the two default ones are:

- /authenticate

    To provide the web token / login.

- /command/&lt;command>

    Calls &lt;command> on the bot and returns the results. Command parameters can be provided via GET/POST params.

# OPTIONS

- port

    Port the bot should listen to for HTTP connections (defaults to 9090)

- cert

    Certificate to use for SSL connections

# HELPERS

- webservice( $path => $callback, ... )

    Register callbacks on given URL paths. See [AnyEvent::HTTPD](https://metacpan.org/pod/AnyEvent::HTTPD) for callback conventions.

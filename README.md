# NAME

Bot::ClueBot - Pluggable jabber bot based on AnyEvent::XMPP

# VERSION

Version 0.02

# SYNOPSIS

Cluebot is a jabber bot which can be extended through plugins.

You can run the bot via the `cluebot command`, which reads configuration from a YAML file
(defaults to `~/.cluebot.yaml`).

A simple configuration file could look like this:

```yaml
    ---
    username: "cluebot"
    hostname: "jabber.example.com"
    domain: "example.com"
    password: "botpassword"
    plugins:
        - LogToRoom:
            log_level: "debug"
        - Chatroom
```

By default, the bot will create a directory on the same location the configuration file
resides, in order to persist each plugin data.

# PLUGINS

There are several plugins available:

- Bot::ClueBot::Plugin::DefaultHelpers

    Provide some basic shortcuts for common tasks.

- Bot::ClueBot::Plugin::Commands

    Command support via private messages.

- Bot::ClueBot::Plugin::Chatroom

    Chatroom support.

- Bot::ClueBot::Plugin::LogToRoom

    Log to a chatroom.

- Bot::ClueBot::Plugin::Admin

    Minimalisting administration commands.

- Bot::ClueBot::Plugin::ACL

    Naive access control implementation for commands.

- Bot::ClueBot::Plugin::WebTokens

    Naive WebToken generation with rotating secrets, to
    provide a minimalistic authentication through other (eg. non-jabber) channels.

- Bot::ClueBot::Plugin::HTTPD

    Expose all commands through an HTTP web interface.

- Bot::ClueBot::Plugin::WebSocket

    Expose all commands through a websocket interface.

If you want to write your own plugins, make sure to read the documentation on
the base Bot::ClueBot::Plugin class. You can use Bot:::ClueBot::Plugin::Sample
as a starter template.

# MAIN CONFIGURATION

These are the base configuration options accepted by the bot.

- **username**

    Username part of the bot account.

- **domain**

    Domain part of the bot account.

- **resource**

    Jabber resource. Defaults to "cluebot-$$".

- **password**

    Password to use during authentication.

- **hostname**

    Jabber host to connect to (defaults to the value provided for _domain_.

- **data\_path**

    Path where plugin state date should be stored.

- **reconnect\_timeout**

    Timeout in seconds between reconnect attempts. If set to 0, then no reconnect will be attempted.

- **ping\_timeout**

    Timeout in seconds for the Ping extension. Defaults to 60.

# METHODS

Bot::ClueBot implements the following methods.

## new

    my $bot = Bot::ClueBot->new( username => 'user', domain => 'domain', ... )

Create a new instance of Bot::Cluebot.

## connect

    my $cv = $bot->connect;
    $cv->recv;

Start connection to the jabber server.

Returns a condition var that can be used to wait for a disconnection.

## connection

    my $connection = $bot->connection;

Return the [AnyEvent::XMPP::IM::Connection](https://metacpan.org/pod/AnyEvent::XMPP::IM::Connection) object

## disconnect

    $bot->disconnect;

Disconnect from the jabber server.

## load\_plugin

    $bot->load_plugin( MyPlugin );
    $bot->load_plugin( MyPlugin => { option1 => 'value1', ... } );
    $bot->load_plugin( MyPlugin => { ... }, $all_options );

Load a cluebot plugin.

The third, optional, parameter can be provided to fetch any dependency plugin
options (otherwise empty options are provided to dependecies).

Returns a true value on success.

## plugin

    my $plugin = $bot->plugin('MyPlugin');

Get a plugin by name.

## plugins

    my @all_plugin_names = $bot->plugins;
    my @all_plugins = map { $bot->plugin($_) }, $bot->plugins;

Return a list of all loaded plugins.

## helper

    $bot->helper( my_helper => sub { my $bot = shift; ... } );
    $bot->helper(
      helper1 => sub { ... },
      helper2 => sub { ... },
    );

Register one or more helper methods on the bot.

Generally used by plugins to extend the base functionality of the bot, and expose it to other plugins.

Helper callbacks receive the bot object as a first parameter, and whatever arguments the caller passed.

## debug, log, warn, error, fatal

    $bot->fatal("This is really wrong");
    $bot->error("This is bad");
    $bot->warn("This is worrying");
    $bot->log("This is interesting");
    $bot->debug("Does this help?");
    $bot->debug("Does this help?", { ... });

Different logging functions on the base bot object, meant to be used also by the plugins.

Right now this generates events, for which the default handler prints to STDOUT/STDERR, but you
can handle those in plugins for fancier logging (see Bot::ClueBot::Plugin::LogToRoom plugin).

# EVENTS

Bot::ClueBot generates the following events.

## connect

Sent when a connection to an XMPP server has been successfully established.

## connection\_setup( $cl )

Sent each time a new instance of AnyEvent::XMPP::IM::Connection is created.

Mostly used by plugins to initialize connection-specific options, like XMPP extensions.

The parameter is the newly created [AnyEvent::XMPP::IM::Connection](https://metacpan.org/pod/AnyEvent::XMPP::IM::Connection) object.

## message( $msg )

Event for incoming direct messages. Empty and echo messages don't generate this event.

The parameter is an [AnyEvent::XMPP::IM::Message](https://metacpan.org/pod/AnyEvent::XMPP::IM::Message) instance.

## fatal, error, warn, log, debug

This events are sent by calls to the methods with the same name on the bot instance.

Generally handled by the bot script, daemon, or plugins to report information via appropriate
channels (eg. STDOUT or a conference room).

With the exception of debug, they all take a message as a parameter. Debug might receive
additional variables to dump with extra information.

# AUTHOR

Quim Rovira, `<met at cpan.org>`

# SUPPORT

- GitHub repository

    [http://github.com/qrovira/cluebot/](http://github.com/qrovira/cluebot/)

# LICENSE AND COPYRIGHT

Copyright 2014 Quim Rovira.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

# SEE ALSO

- [AnyEvent::XMPP](https://metacpan.org/pod/AnyEvent::XMPP) - AnyEvent modules to handle XMPP connections, on top
of which this modules are built.
- [Bot::Jabbot](https://metacpan.org/pod/Bot::Jabbot) - Another jabber bot based on AnyEvent::XMPP.

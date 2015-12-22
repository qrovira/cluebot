# NAME

Bot::ClueBot::Plugin::Graphite - Plugin that provides integration with Graphite

# VERSION

Version 0.01

# SYNOPSIS

This plugin provides functionality to integrate with Graphite, to request some simple metrics,
and to get notified of certain events.

# OPTIONS

- base\_url

    Base url where graphite can be reached, including protocol, hostname and port if needed.

    (eg. `http://graphite-host/`)

- socks

    Optional socks proxy url to use to connect to graphite.

    (eg. `socks5://internal-proxy:8080`)

- targets

    Hash map of common graphite metrics using alias to their default configurations.
    This targets can later be used on commands, to avoid typing.

# COMMANDS

- graphite\_check

    Fetch recent (2 min average) data for a given graphite metric.

- graphite\_subscribe

    Get notifications when conditions are met on a graphite metric

# HELPERS

- graphite\_data( %opts, $callback )

    Retrieve data from graphite, and call $callback with results (a hash ref) or errors (string).

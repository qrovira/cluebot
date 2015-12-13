# NAME

Bot::ClueBot::Plugin::Run - Shell command execution plugin for Bot::ClueBot

# VERSION

Version 0.01

# SYNOPSIS

Provides shell command execution features to Bot::ClueBot.

This plugin is restricted to the 'Run' ACL group.

# OPTIONS

- commands

    Hash that maps command aliases to the actual shell commands executed.

    Values can either be strings specifying the full cmdline, or a hash specifying
    any of the following options:

    - cmdline

        Full cmdline to be executed, either a single string, or an array consisting of the path to executable and the arguments.

    - acl

        Access control list to check.

# HELPERS

- sample( $arg1, ... )

    A sample helper

# COMMANDS

- sample

    A sample command

# EVENTS

-

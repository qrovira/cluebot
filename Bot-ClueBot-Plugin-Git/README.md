# NAME

Bot::ClueBot::Plugin::Git - ClueBot plugin that provides Git integration

# VERSION

Version 0.02

# SYNOPSIS

This plugin provides access to Git local git repositories, so users can request
information via commands, and other plugins can get repository handles via a
helper.

# ACL

Access to this plugin's functionality requires `git` ACL membership.

# OPTIONS

- gitroot

    Base directory for git repositories. All subdirectories will be checked at start
    time, when checking for repos.

- repos

    Repositories to register.

    It can either be an array of paths to the repositories, or a hash that maps repository
    names to their paths.

- log\_max\_commits

    Maximum number of commits that can be returned when fetching information via commands.

# HELPERS

- repository( $name )

    Returns the AnyEvent::Git::Wrapper object for the given reposiroty alias.

# COMMANDS

- git\_repos

    Display a list of known repositories

- git\_log $repo \[$ref \[$num\] \]

    Display the commig short log for a given repository

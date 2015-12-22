package Bot::ClueBot::Plugin::Graphite;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

our $VERSION = '0.01';

=head1 NAME

Bot::ClueBot::Plugin::Graphite - Graphite plugin for Bot::ClueBot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Provides Graphite features to Bot::ClueBot

=head1 OPTIONS

=over

=item option1

Descriptiton of option1

=back

=head1 HELPERS

=over

=item sample( $arg1, ... )

A sample helper

=back

=head1 COMMANDS

=over

=item sample

A sample command

=back

=head1 EVENTS

=over

=item

=back

=cut


sub requires { qw/Commands/ }

sub init {
    my $self = shift;
    my $args = {
        %{ shift // {} },
    };

    $self->bot->helper(
        sample => sub {
            my ($bot, $arg1 ) = @_;

            ...
        },
    );

    $self->bot->command(
        sample => {
            help => "Graphite command",
            help_usage => "sample ...",
            category => "Graphite",
        } => sub {
            my ($bot, %context) = @_;
            my ($user,$resource) = split '/', $context{source_jid};

            $context{reply}->("Some text");

            ...
        },
    );
}



1;

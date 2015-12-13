package Bot::ClueBot::Plugin::RedisSub;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

use AnyEvent::Redis;

our $VERSION = '0.01';

=head1 NAME

Bot::ClueBot::Plugin::RedisSub - RedisSub plugin for Bot::ClueBot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Provides Redis PubSub features to Bot::ClueBot

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


sub requires { qw/Commands ACL/ }

sub init {
    my $self = shift;
    my $args = {
        %{ shift // {} },
    };

    $self->connect;

    $self->bot->helper(
        redis_sub => sub {
            my ($bot, $chan) = @_;

            ...
        },
    );

    $self->bot->command(
        sample => {
            help => "RedisSub command",
            help_usage => "sample ...",
            category => "RedisSub",
        } => sub {
            my ($bot, %context) = @_;
            my ($user,$resource) = split '/', $context{source_jid};

            $context{reply}->("Some text");

            ...
        },
    );
}

sub connect {
    my $self = shift;

    return AnyEvent::Redis->new(
        host       => $self->{host},
        port       => $self->{port},
        on_error   => sub { $self->bot->warn("Redis error: ".shift); },
        on_cleanup => sub { AE::
    );
}

1;


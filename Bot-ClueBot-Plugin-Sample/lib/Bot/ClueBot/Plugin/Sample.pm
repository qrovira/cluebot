package Bot::ClueBot::Plugin::Sample;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

our $VERSION = '0.01';

=head1 NAME

Bot::ClueBot::Plugin::Sample - Sample plugin for Bot::ClueBot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Provides Sample features to Bot::ClueBot

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
            category => "Sample",
            help => "Sample command",
            help_usage => "sample ...",
            params => [
                param_name => {
                    required => 1,
                    help => "Param help line",
                }
            ]
        } => sub {
            my ($context) = @_;

            $context->reply("Some text");
            ...
        },
    );
}



1;

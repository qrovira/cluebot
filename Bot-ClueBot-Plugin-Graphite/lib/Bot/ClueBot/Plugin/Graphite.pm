package Bot::ClueBot::Plugin::Graphite;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

use JSON;
use List::Util qw/ sum /;
use AnyEvent::HTTP;
use AnyEvent::HTTP::Socks;

our $VERSION = '0.01';

=head1 NAME

Bot::ClueBot::Plugin::Graphite - Plugin that provides integration with Graphite

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This plugin provides functionality to integrate with Graphite, to request some simple metrics,
and to get notified of certain events.

=head1 OPTIONS

=over

=item base_url

Base url where graphite can be reached, including protocol, hostname and port if needed.

(eg. C<http://graphite-host/>)

=item socks

Optional socks proxy url to use to connect to graphite.

(eg. C<socks5://internal-proxy:8080>)

=item targets

Hash map of common graphite metrics using alias to their default configurations.
This targets can later be used on commands, to avoid typing.

=back

=head1 COMMANDS

=over

=item graphite_check

Fetch recent (2 min average) data for a given graphite metric.

=item graphite_subscribe

Get notifications when conditions are met on a graphite metric

=back

=head1 HELPERS

=over

=item graphite_data( %opts, $callback )

Retrieve data from graphite, and call $callback with results (a hash ref) or errors (string).

=back

=cut


sub requires { qw/Commands/ }

sub init {
    my $self = shift;
    my $args = {
        targets => {},
        %{ shift // {} },
    };

    $self->bot->helper(
        graphite_data => sub {
            my $bot = shift;
            my $callback = pop;
            my %opts = @_;

            $opts{target} = $args->{targets}{$opts{target}}
                if $args->{targets}{$opts{target}};

            $opts{format} = 'json';
            $opts{from} //= '-5minutes';
            $opts{until} //= 'now';

            my $url = $args->{base_url}.'/render/?'. join '&', map("$_=$opts{$_}", keys %opts);

            $bot->debug("Requesting graphite data from $url".($args->{socks}?" (using socke proxy $args->{socks})":""));

            http_request
                GET => $url,
                ( $args->{socks} ? ( socks => $args->{socks} ) : () ),
                sub {
                    my ($json, $headers) = @_;

                    if( $headers->{Status} eq "200" ) {
                        if( my ($metric) = eval { @{ decode_json $json }; } ) {
                            $callback->($metric);
                        } else {
                            my $error = "Could not deserialzie graphite JSON response: ".($@ // 'Unknown error');
                            $bot->warn( $error );
                            $callback->( $error );
                        }
                    } else {
                        my $error = "Error fetching graphite metrics (status=$headers->{Status})";
                        $bot->warn( $error );
                        $callback->( $error );
                    }
                };
        }
    );

    $self->bot->command(
        graphite_check => {
            category => "Graphite",
            help => "Fetch recent (2 min average) data for a given graphite metric.",
            help_usage => "graphite_check some.graphite.target",
            params => [
                target => {
                    help => "Graphite target, or alias of a registered target",
                    required => 1,
                }
            ]
        } => sub {
            my ($context) = @_;
            my $target = $context->{params}{target};
            $self->bot->graphite_data(
                target => $target,
                from => "-2minutes",
                until => "now",
                sub {
                    my $metric = shift;

                    if( ! ref $metric ) {
                        $context->reply( "Error fetching graphite data: $metric." );
                    }
                    elsif( my @data = grep { defined $_->[0] } @{$metric->{datapoints}} ) {
                        $context->reply(
                            "For target $target, average of last 2 minutes is: ".
                            sum( map $_->[0], @data) / (@data || 1)
                        );
                    }
                    else {
                        $context->reply( "Recent data not found for ttarget $target." );
                    }

                }
            );
        },
    );
}



1;

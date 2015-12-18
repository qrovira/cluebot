package Bot::ClueBot::Plugin::WebSocket;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.14.0;

use AnyEvent::Socket qw(tcp_server);
use AnyEvent::WebSocket::Server;
use JSON;

our $VERSION = '0.02';

=head1 NAME

Bot::ClueBot::Plugin::WebSocket - ClueBot plugin that provides a websocket interface to the bot's features

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

When enabled, this plugin will listen for websocket connections to a given port (defaults to 9191),
through which you can execute commands on the bot.

=head1 OPTIONS

=over

=item port

Port on which to listen for connections. Defaults to 9191.

=back

=head1 HELPERS

=over

=item ws_connection( $user )

Returns any websocket connections by the given user.

=item ws_send( $user, $data )

Send a message to the user via webssocket.

=back

=head1 COMMANDS

=over

=item websocket_status

Reports all currently open websocket connections

=back

=cut

sub requires { qw/ Commands WebTokens /; }

sub init {
    my $self = shift;
    my $args = {
        port => 9191,
        %{ shift // {} },
    };

    $self->{connections} = {};
    $self->{connection_sequences} = {};

    $self->{server} = AnyEvent::WebSocket::Server->new(
        validator => sub {
            my $request = shift;
            # Having the token on the URL is not acceptable even in WSS, but for the sake of getting something working quick, here we go..
            my ($user, $token) = $request->resource_name =~ m#^/([^/]+)/([^/]+)$#;

            unless( defined $user ) {
                $self->bot->warn("Invalid websocket connection from ".$request->resource_name);
                die "INVALID_REQUEST";
            }

            unless( defined($token) && ( $self->bot->decode_token($token) // '' ) eq $user ) {
                $self->bot->warn("Invalid token for websocket connection from ".$user);
                die "FORBIDDEN";
            }

            $self->bot->debug("Incomming websocket connection for: ".$request->resource_name);

            $user;
        }
    );

    $self->{tcp_server} = tcp_server undef, $args->{port}, sub {
        my ($fh) = @_;
        $self->{server}->establish($fh)->cb(sub {
            my ($connection, $user) = eval { shift->recv };
            if($@) {
                $self->bot->warn("Invalid connection request: $@\n");
                close($fh);
                return;
            }
            $self->bot->debug("Accepted websocket connection request for $user");
            $self->{connections}{$user} = $connection;
            $self->bot->ws_send($user, "Welcome, $user!");
            $connection->on(each_message => sub { $self->handle_websocket_message( shift, shift, $user ) } );
            $connection->on(finish => sub {
                undef $connection;
                delete $self->{connections}{$user};
                $self->bot->debug("Disconnected websocket for $user");
            });
        });
    };

    $self->bot->helper(
        ws_connection => sub {
            my ($bot, $user) = @_;
            return $self->{connections}{$user};
        },
        ws_send => sub {
            my ($bot, $user, $data) = @_;
            my $conn = $self->{connections}{$user} // return 0;
            my $body = eval { encode_json( ref($data) ? $data : { text => $data } ); };
            my $msg = AnyEvent::WebSocket::Message->new( body => $body );
            $conn->send( $msg );
            return 1;
        }
    );

    $self->bot->command(
        websocket_status => {
            help => "Display status of the websocket interface",
            help_usage => "websocket_status",
            category => "WebSockets",
        } => sub {
            my ($context) = @_;
            $context->reply(
                "Total connections: ".scalar(keys %{ $self->{connections} // {} })."\n\t".
               join("\n\t", keys %{ $self->{connections} // {} })
            );
        },
    );

}

sub handle_websocket_message {
    my ($self, $connection, $message, $user) = @_;

    return unless $message->is_text;

    my $body = $message->decoded_body;
    $self->bot->debug("Received websocket data: $body");
    my $data = eval { decode_json($body); };

    if( ! defined $data ) {
        my $msg = "Badly formed JSON request via websocket: $body.\nError: $@";
        $self->bot->warn($msg);
        $self->bot->ws_send( $user, { error => $msg } );
    } elsif( !$data->{command} ) {
        my $msg = "Request has no command part";
        $self->bot->warn($msg);
        $self->bot->ws_send( $user, { error => $msg } );
    } else {
        my $context = Bot::ClueBot::Plugin::Commands::Context::WebSocket->new(
            bot => $self->bot,
            (
                defined($data->{argline}) ? (argline => $data->{argline}) :
                keys(%{ $data->{params} // {} }) ? (params => $data->{params}) :
                ()
            ),
            user => $user,
            # Meant for client-side to relate responses to requests where needed
            seq => $data->{seq} // $self->{connection_sequences}{$user}++,
        );
        $self->bot->handle_command( $data->{command}, $context );
    }
}

package Bot::ClueBot::Plugin::Commands::Context::WebSocket;

our @ISA = ('Bot::ClueBot::Plugin::Commands::Context');

sub new {
    my ($proto, %args) = @_;
    my $user = delete $args{user};

    my $self = $proto->SUPER::new(
        %args,
        source_type => 'websocket',
        source_jid  => $user.'/ws',
        source_user => $user,
    );

    return $self;
}

sub reply {
    my ($self, $data) = @_;
    $self->{bot}->ws_send( $self->{source_user}, { seq => $self->{seq}, response => $data } );
}

sub private_reply { shift->reply(@_); }

1;

package Bot::ClueBot::Plugin::Chatroom;

use warnings;
use strict;
use 5.10.0;

use base 'Bot::ClueBot::Plugin';

use AnyEvent::XMPP::Ext::MUC;
use YAML;

=head1 NAME

Bot::ClueBot::Plugin::Chatroom - Chatroom support

=head1 SYNOPSIS

Add support for XMPP multi-user chat extension to cluebot, and also add support
for receiving commands on chatrooms.

=head1 OPTIONS

=over

=item

=back

=head1 COMMANDS

=head1 HELPERS

=head1 EVENTS

=cut


sub requires { qw/ Commands DefaultHelpers / }

sub init {
    my $self = shift;

    my $args = {
        domain => ('conference.'.$self->bot->{domain}),
        nick   => $self->bot->{username},
        rooms  => {},
        %{ shift // {} }
    };

    # Options
    $self->{domain} = $args->{domain};
    $self->{nick} = $args->{nick};
    $self->data->{rooms} = $self->{rooms} = $self->data->{rooms} // $args->{rooms};

    $self->bot->reg_cb( connection_setup => sub { $self->_connection_setup(@_); } );

    # Hook in XMPP chatroom-related events
    $self->bot->reg_cb(
        connect => sub {
            foreach my $room ( grep { $self->{rooms}{$_}{autojoin} } keys %{ $self->{rooms} } ) {
                my $mucroom = $self->bot->get_chatroom( $room );
                $self->_do_join_room( $room );
            }
        },
    );

    $self->bot->helper(
        get_chatroom => \&_helper_get_chatroom,
        join_chatroom => \&_helper_join_chatroom,
        leave_chatroom => \&_helper_leave_chatroom,
        normalize_room_name => \&_helper_normalize_room_name,
    );

    $self->bot->command(
        join_chatroom => {
            help => "Join a given chatroom",
            params => [
                chatroom => {
                    help => "Chatroom to join. The name does not need to be prefixed with '#'",
                    required => 1,
                },
            ],
            category => "Chatrooms",
        } => sub {
            my ($context) = @_;
            $context->{bot}->join_chatroom( $context->{params}{chatroom} );
            $context->reply("Joining room #$context->{params}{chatroom}!");
        },

        leave_chatroom => {
            help => "Leave a given chatroom",
            params => [
                chatroom => {
                    help => "Chatroom to leave. The name does not need to be prefixed with '#'",
                    required => 1,
                }
            ],
            category => "Chatrooms",
        } => sub {
            my ($context) = @_;
            $context->{bot}->leave_chatroom( $context->{params}{chatroom}, sub {
                $context->{reply}->("Left room #$context->{params}{chatroom}!");
            } );
        },

        list_chatrooms => {
            help => "List all known chatrooms and configuration",
            category => "Chatrooms",
        } => sub {
            my ($context) = @_;
            $context->reply( $self->{rooms} );
        },

        config_chatroom => {
            help => "Change a configuration option of a given chatroom",
            params => [
                chatroom => {
                    help => "Chatroom to change setup of.",
                    required => 1,
                },
                option => {
                    help => "Option to change the value of. Can be any of: quiet, autojoin, password, prefix",
                    required => 1,
                },
                value => {
                    help => "Value to set for the specified option.",
                    required => 1,
                }
            ],
            category => "Chatrooms",
        } => sub {
            my ($context) = @_;
            my $room = $context->{bot}->normalize_room_name( $context->{params}{chatroom} );

            unless( $self->{rooms}{$room} ) {
                $context->reply( "Unknown room $room." );
                return;
            }

            $self->{rooms}{$room}{ $context->{params}{option} } = $context->{params}{value};
            $context->reply( "Set $context->{params}{option} to $context->{params}{value} for room $room." );
        },

        stfu => {
            help => "Go into quiet mode in the room this command is sent",
            category => "Chatrooms",
        } => sub {
            my ($context) = @_;

            if( $context->{source_room} ) {
                $context->reply( "Ook, going into quiet mode... *sigh*" );
                $self->{rooms}{$context->{source_room}}{quiet} = 1;
            } else {
                $context->reply( "Nah, I was born with license to spam people" );
            }
        }
    );
}

sub _helper_get_chatroom {
    my ($bot, $room) = @_;
    $room = $bot->normalize_room_name( $room );
    use Carp qw/cluck/;
    use Data::Dumper;
    cluck "Hmmm...".Dumper($bot->{ext}) unless $bot->{ext}{muc};
    return $bot->{ext}{muc}->get_room( $bot->connection, $room );
}

sub _helper_join_chatroom {
    my ($bot, $room, $options) = @_;
    my $self = $bot->plugin('Chatroom');

    $room = $bot->normalize_room_name( $room );

    return if( $self->{rooms}{$room} );

    $options = {
        autojoin => 1,
        quiet    => 0,
        password => undef,
        %{ $options // {} }
    };

    $self->{rooms}{$room} = $options;

    $self->_do_join_room($room)
        if  $self->bot->connection && $self->bot->connection->is_connected;
}

sub _helper_leave_chatroom {
    my ($bot, $room, $cb) = @_;
    my $self = $bot->plugin('Chatroom');
    $room = $bot->normalize_room_name( $room );
    my $mucroom = $bot->get_chatroom( $room );

    $mucroom->send_part("I'm outta here", sub { $bot->log("Left room $room"); $cb->(@_) if $cb; })
        if $mucroom;

    if( $self->{rooms}{$room} && $self->{rooms}{$room}{autojoin} ) {
        $self->{rooms}{$room}{autojoin} = 0;
        $bot->log("Disabled autojoin for room $room");
    }
}

sub _helper_normalize_room_name {
    my ($bot, $room) = @_;

    $room =~ s/^#+//;
    $room .= '@'.$bot->plugin('Chatroom')->{domain}
        unless $room =~ m#@#;

    return $room;
}

sub _do_join_room {
    my ($self, $room) = @_;
    $room = $self->bot->normalize_room_name( $room );
    my $options = $self->{rooms}{$room};

    return unless $options;

    $self->bot->log("Joining room $room");
    $self->bot->{ext}{muc}->join_room(
        $self->bot->{connection},
        $room,
        $self->{nick},
        history => { stanzas => 0 },
        ( defined $options->{password} ? (password => $options->{password}) : () ),
    );
}


sub _connection_setup {
    my $self = shift;
    my $bot = shift;
    my $cl = shift;

    # Add MUC extension to the xmpp connection
    my $muc = $self->bot->{ext}{muc} = AnyEvent::XMPP::Ext::MUC->new( disco => $bot->{ext}{disco} );
    $cl->add_extension($muc);

    $muc->reg_cb(
        enter => sub {
            my ($muc, $room, $user) = @_;

            $self->bot->log( "Joined chatroom ".$room->jid );
            $self->event( join => @_ );
        },
        leave => sub {
            my ($muc, $room, $user) = @_;

            #TODO if(room->reconnect) then call join again

            $self->bot->log( "Left chatroom ".$room->jid );
            $self->event( leave => @_ );
        },
        error => sub {
            my ($muc, $room, $error) = @_;
            $self->bot->error( "MUC error (".($room->jid // "unknown room")."): ".$error->string."\n" );
        },
        join_error => sub {
            my ($muc, $room, $error) = @_;

            $self->bot->error( "MUC error (".($room->jid // "unknown room").") : join error: ".$error->string );
        },
        message => sub {
            my ($muc, $room, $msg, $is_echo) = @_;
            my $room_options = $self->{rooms}{ $room->jid };

            return if $is_echo;

            # Trigger a generic room message event
            $self->event( message => $room, $msg );

            # Only care about stuff sent with a poke to us (e.g: "cluebot: stfu")
            my $prefix = $room_options->{prefix} // ( $room->get_me ? $room->get_me->nick.":" : $self->{nick} );

            return unless $msg->body && (
                ( $msg->type eq 'groupchat' && $msg->body =~ qr#^$prefix\s+(?<command>\w+)(?:\s+(?<argline>.*))?$# ) ||
                ( $msg->type eq 'chat' && $msg->body =~ qr#^(?<command>\w+)(?:\s+(?<argline>.*))?$# )
            );

            my $room_user = $room->get_user( $msg->from_nick );

            my $context = Bot::ClueBot::Plugin::Commands::Context::Chatroom->new(
                bot          => $self->bot,
                message      => $msg,
                room         => $room,
                room_options => $room_options,
                argline      => $+{argline},
            );

            $self->bot->handle_command( $+{command}, $context );
        },

    );
}

package Bot::ClueBot::Plugin::Commands::Context::Chatroom;

use YAML;

our @ISA = ('Bot::ClueBot::Plugin::Commands::Context::Message');

sub new {
    my ($proto, %args) = @_;
    my $msg = $args{message};
    my $room = $args{room};

    die "Invalid source message specified"
        unless $msg && ref($msg) && $msg->isa('AnyEvent::XMPP::Ext::MUC::Message');

    die "Invalid source message room specified"
        unless $room && ref($room) && $room->isa('AnyEvent::XMPP::Ext::MUC::Room');

    my $room_user = $room->get_user( $msg->from_nick );

    my $self = $proto->SUPER::new(
        %args,
        source_room => $room->jid,
        source_user => ($room_user ? ($room_user->real_jid // "unknown") : "unknown"),
    );

    return $self;
}

sub reply {
    my ($self, $data) = @_;

    if( $self->{source} eq 'groupchat' && $self->{room_options}->{quiet} ) {
        return $self->private_reply( $data );
    }

    my $reply = $self->{message}->make_reply;

    $reply->add_body( ref($data) ? Dump($data) : $data );
    $reply->send;
}

sub private_reply {
    my ($self, $data) = @_;
    my $reply = $self->{bot}->message( $self->{message}->from );

    $reply->add_body( ref($data) ? Dump($data) : $data );
    $reply->send;
}



1;

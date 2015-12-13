package Bot::ClueBot::Plugin::LogToRoom;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use 5.10.0;

use Sys::Hostname;

my %LOG_LEVELS = (
    debug => [ qw/ debug log warn error fatal / ],
    info  => [ qw/ log warn error fatal / ],
    warn  => [ qw/ warn error fatal / ],
    error => [ qw/ error fatal / ],
    fatal => [ qw/ fatal / ],
);

sub requires { qw/ Chatroom / }

sub init {
    my $self = shift;
    my $args = {
        buffer_size => 1000,
        log_level   => 'warn',
        room        => $self->bot->{username}.'_log',

        %{ shift // {} }
    };

    $self->data->{room} //= $args->{room};
    $self->{buffer_size} = $args->{buffer_size};
    $self->{log_level} = $args->{log_level};
    $self->{buffer} = [];

    $self->bot->join_chatroom( $self->data->{room} );

    $self->bot->plugin('Chatroom')->reg_cb(
        join => sub {
            my ($chatroom, $muc, $room, $user) = @_;

            if( $room->jid eq $self->data->{room} ) {
                $self->process_buffer;
                $self->bot->log( $self->{nick}." reporting from ".hostname." (PID $$)" );
            }
        },
    );

    $self->bot->reg_cb(
        map {
            my $log_type = $_;

            $log_type => sub {
                my ($bot, $msg, @extra) = @_;

                $self->buffer_log( [ $log_type => $msg, @extra ] );
            },
        } @{ $LOG_LEVELS{ $self->{log_level} } }
    );
}

sub buffer_log {
    my ($self, $event) = @_;
    
    push @{ $self->{buffer} }, $event;

    if( scalar @{ $self->{buffer} } > $self->{buffer_size} ) {
        push @{ $self->{buffer} }, [ warn => "Log buffer overflow!" ];
        splice @{ $self->{buffer} }, $self->{buffer_size};
    }

    $self->process_buffer;

    return;
}

sub process_buffer {
    my ($self) = @_;

    return unless $self->bot->connection && $self->bot->connection->is_connected;

    my $room = $self->bot->get_chatroom( $self->data->{room} );

    return unless $self->bot->connection && $self->bot->connection->is_connected && $room && $room->is_connected;

    my @pending = @{ $self->{buffer} // [] };
    $self->{buffer} = [];

    while( my $log = shift @pending ) {
        my $cmsg = $room->make_message(
            body => (
                uc(shift @$log).": ".shift(@$log).
                ( @$log ? "\n".Data::Dumper->new($log)->Terse(1)->Maxdepth(3)->Sortkeys(1)->Indent(1)->Deepcopy(1)->Pad("** ")->Dump : "" )
            )
        );
        $cmsg->send;
    }

    return;
}

1;

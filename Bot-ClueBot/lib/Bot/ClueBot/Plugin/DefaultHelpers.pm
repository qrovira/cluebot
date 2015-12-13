package Bot::ClueBot::Plugin::DefaultHelpers;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use 5.10.0;

use utf8;

sub init {
    my ($self) = @_;

    $self->bot->helper(

        message => sub {
            my ($self, $to) = @_;

            return AnyEvent::XMPP::IM::Message->new( to => $to, connection => $self->{connection} );
        },

        send_to_user => sub {
            my ($self, $to, $message) = @_;

            my $msg = $self->message($to);
            $msg->add_body($message);
            $msg->send;

            return;
        },

    );

}


1;

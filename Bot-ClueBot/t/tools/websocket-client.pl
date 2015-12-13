#!/usr/bin/env perl
#

use warnings;
use strict;
use 5.014;

use AnyEvent::WebSocket::Client;

my $EP = $ARGV[0] // 'ws://localhost:9191/some.dude@some-place.com/no-token';

my $client = AnyEvent::WebSocket::Client->new;
my $cv = AnyEvent->condvar;
my $w;

say "Connecting to $EP...";

$client->connect($EP)->cb(sub {
    my $connection = eval { shift->recv };

    if($@) {
        say "Error connecting: $@";
        exit 1;
    }

    say "Connected!";

    $connection->on(each_message => sub {
        my ($connection, $message) = @_;
        say "Received message from endpoint:\n    ".$message->decoded_body;
    });
    
    $connection->on(finish => sub {
        my ($connection) = @_;
        say "Disconnected!";
        $cv->send;
    });

    $w = AnyEvent->io (fh => \*STDIN, poll => 'r', cb => sub {
        chomp (my $input = <STDIN>);
        if( $input eq "quit" ) {
            say "Bye!";
            $cv->send;
        } else {
            say "Sending $input...";
            my $msg = AnyEvent::WebSocket::Message->new( body => $input );
            $connection->send( $msg );
        }
    });
});

$cv->recv;

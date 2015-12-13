package Bot::ClueBot;

use 5.10.0;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Ext::Ping;
use AnyEvent::XMPP::Ext::Receipts;

use parent 'Object::Event';

# This package var is just to debug raw XMPP streams, and can be sett via the cluebot script
# Bear in mind it's XMPP, you might get angry looking at this dump
our $DUMP = 0;


=head1 NAME

Bot::ClueBot - Pluggable jabber bot based on AnyEvent::XMPP

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Cluebot is a jabber bot which can be extended through plugins.

You can run the bot via the L<cluebot> command, which reads configuration from a YAML file
(defaults to F<~/.cluebot.yaml>).

A simple configuration file could look like this:

  ---
  username: "cluebot"
  hostname: "jabber.example.com"
  domain: "example.com"
  password: "botpassword"
  plugins:
      - LogToRoom:
          log_level: "debug"
      - Chatroom

By default, the bot will create a directory on the same location the configuration file
resides, in order to persist each plugin data.

=head1 PLUGINS

There are several plugins available:

=over

=item L<Bot::ClueBot::Plugin::DefaultHelpers>

Provide some basic shortcuts for common tasks.

=item L<Bot::ClueBot::Plugin::Echo>

Sample plugin that echoes back any direct messages received.

=item L<Bot::ClueBot::Plugin::Commands>

Command support via private messages.

=item L<Bot::ClueBot::Plugin::Chatroom>

Chatroom support.

=item L<Bot::ClueBot::Plugin::LogToRoom>

Log to a chatroom.

=item L<Bot::ClueBot::Plugin::Admin>

Minimalisting administration commands.

=item L<Bot::ClueBot::Plugin::ACL>

Naive access control implementation for commands.

=item L<Bot::ClueBot::Plugin::WebTokens>

Naive WebToken generation with rotating secrets, to
provide a minimalistic authentication through other (eg. non-jabber) channels.

=item L<Bot::ClueBot::Plugin::HTTPD>

Expose all commands through an HTTP web interface.

=item L<Bot::ClueBot::Plugin::WebSocket>

Expose all commands through a websocket interface.

=back

If you want to write your own plugins, make sure to read the documentation on
the base L<Bot::ClueBot::Plugin> class. You can use L<Bot:::ClueBot::Plugin::Sample>
as a starter template.

=head1 MAIN CONFIGURATION

These are the base configuration options accepted by the bot.

=over

=item B<username>

Username part of the bot account.

=item B<domain>

Domain part of the bot account.

=item B<resource>

Jabber resource. Defaults to "cluebot-$$".

=item B<password>

Password to use during authentication.

=item B<hostname>

Jabber host to connect to (defaults to the value provided for I<domain>.

=item B<data_path>

Path where plugin state date should be stored.

=item B<reconnect_timeout>

Timeout in seconds between reconnect attempts. If set to 0, then no reconnect will be attempted.

=item B<ping_timeout>

Timeout in seconds for the Ping extension. Defaults to 60.

=back

=head1 METHODS

L<Bot::ClueBot> implements the following methods.

=head2 new

  my $bot = Bot::ClueBot->new( username => 'user', domain => 'domain', ... )

Create a new instance of Bot::Cluebot.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = {
        reconnect_timeout => 5,
        pint_timeout => 60,
        %args,
        plugins => {},
    };

    bless $self, $class;

    $self->set_exception_cb( sub { $self->_handle_exception(@_); } );

    # Load default plugins
    $self->load_plugin($_) foreach( qw/ DefaultHelpers / );

    return $self;
}


=head2 connect

  my $cv = $bot->connect;
  $cv->recv;

Start connection to the jabber server.

Returns a condition var that can be used to wait for a disconnection.

=cut
sub connect {
    my $self = shift;

    $self->{disconnect_cv} = AnyEvent->condvar;

    $self->_connection_setup;
    $self->log("Connecting...");
    $self->{connection}->connect;

    return $self->{disconnect_cv};
}

=head2 connection

  my $connection = $bot->connection;

Return the L<AnyEvent::XMPP::IM::Connection> object

=cut
sub connection {
    my ($self) = @_;

    return $self->{connection};
}

=head2 disconnect

  $bot->disconnect;

Disconnect from the jabber server.

=cut
sub disconnect {
    my $self = shift;

    $self->{connection}->disconnect;
}

=head2 load_plugin

  $bot->load_plugin( MyPlugin );
  $bot->load_plugin( MyPlugin => { option1 => 'value1', ... } );
  $bot->load_plugin( MyPlugin => { ... }, $all_options );

Load a cluebot plugin.

The third, optional, parameter can be provided to fetch any dependency plugin
options (otherwise empty options are provided to dependecies).

Returns a true value on success.

=cut
sub load_plugin {
    my ($self, $name, $options, $all_plugin_options) = @_;
    my $rclass = __PACKAGE__."::Plugin::".$name;

    $self->debug("Loading plugin $rclass..");

    if( $self->plugin($name) ) {
        $self->debug("Plugin $name is already loaded.");
        return 1;
    }

    unless( eval "use $rclass; 1;" ) {
        $self->warn("Failed to load plugin $name:\n$@");
        return;
    }

    foreach my $missing ( $rclass->requires ) {
        next if $self->plugin($missing);
        my $missing_options = $all_plugin_options->{$missing} // {};
        $self->log("Plugin $name requires plugin $missing, trying to autoload it");
        unless( $self->load_plugin($missing, $missing_options, $all_plugin_options) ) {
            $self->error("Failed to load dependency $missing, so $name also won't be loaded");
            return;
        }
    }

    my $plugin = $rclass->new($self, $options);

    $plugin->set_exception_cb( sub { $self->_handle_plugin_exception($plugin, @_); } );

    $self->{plugins}{$name} //= $plugin;

    $self->debug( "Registered plugin $name" );

    return 1;
}

=head2 plugin

  my $plugin = $bot->plugin('MyPlugin');

Get a plugin by name.

=cut
sub plugin {
    my $self = shift;
    my $name = shift;

    return $self->{plugins}{$name};
}

=head2 plugins

  my @all_plugin_names = $bot->plugins;
  my @all_plugins = map { $bot->plugin($_) }, $bot->plugins;

Return a list of all loaded plugins.

=cut
sub plugins {
    my $self = shift;

    return keys %{ $self->{plugins} // {} };
}

=head2 helper

  $bot->helper( my_helper => sub { my $bot = shift; ... } );
  $bot->helper(
    helper1 => sub { ... },
    helper2 => sub { ... },
  );

Register one or more helper methods on the bot.

Generally used by plugins to extend the base functionality of the bot, and expose it to other plugins.

Helper callbacks receive the bot object as a first parameter, and whatever arguments the caller passed.

=cut
sub helper {
    my ($self, %helpers) = @_;

    $self->{helpers}{$_} = $helpers{$_}
        foreach( keys %helpers );
}

# I pretty much copied this from Mojolicious.. thanks sri!
sub AUTOLOAD {
    my $self = shift;

    my ($package, $method) = split /::(\w+)$/, our $AUTOLOAD;

    return $self->warn("Undefined subroutine &${package}::$method called")
        unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);
           
    # Call helper with current controller
    return $self->warn("Can't locate object method \"$method\" via package \"$package\"")
        unless my $helper = $self->{helpers}{$method};

    return $self->$helper(@_);
}

=head2 debug, log, warn, error, fatal

  $bot->fatal("This is really wrong");
  $bot->error("This is bad");
  $bot->warn("This is worrying");
  $bot->log("This is interesting");
  $bot->debug("Does this help?");
  $bot->debug("Does this help?", { ... });

Different logging functions on the base bot object, meant to be used also by the plugins.

Right now this generates events, for which the default handler prints to STDOUT/STDERR, but you
can handle those in plugins for fancier logging (see L<Bot::ClueBot::Plugin::LogToRoom> plugin).

=cut
sub debug { shift->event( debug => @_ ) }
sub log   { shift->event( log   => @_ ) };
sub warn  { shift->event( warn  => @_ ) };
sub error { shift->event( error => @_ ) };
sub fatal { shift->event( fatal => @_ ) };


#
# Some privates ahead
#

sub _connection_setup {
    my $self = shift;

    my %opts = (
        username => $self->{username},
        domain   => $self->{domain},
        resource => ($self->{resource} // "cluebot-$$"),
        password => $self->{password},
        host     => $self->{hostname} // $self->{domain},
        dont_retrieve_roster => 1,
    );

    $self->debug("Connection setup", { %opts, password => 'undisclosed' } );

    my $cl = $self->{connection} = AnyEvent::XMPP::IM::Connection->new( %opts );

    $cl->reg_cb(
        session_ready => sub {
            my ($cl) = @_;

            $self->log("Connected!");
            $self->event('connect');
        },
        message => sub {
            my ($cl, $msg, $is_echo) = @_;

            return if $is_echo or not defined $msg->body;

            $self->debug( "Received direct message from ".$msg->from.": ".$msg->body );

            $self->event( message => $msg );
        },
        disconnect => sub {
            my ($cl, $host, $port, $msg);

            $self->log("Disconnected");
            $self->_connection_cleanup;

            if( $self->{reconnect_timeout} ) {
                $self->log("Waiting $self->{reconnect_timeout} seconds before reconnecting...");
                $self->{reconnect_cv} = AnyEvent->timer( after => 0+$self->{reconnect_timeout}, cb => sub { $self->connect; } );
            } else {
                $self->{disconnect_cv}->send;
            }
        },
        contact_request_subscribe => sub {
            my ($cl, $rooster, $contact, $message) = @_;

            # Polite bots are polite
            $contact->send_subscribed;
            # And a bit of a stalker too
            $contact->send_subscribe( $message );
        },
        debug_send => sub {
            my ($cl, $data) = @_;

            $self->debug("Sent:\n$data\n") if $DUMP;
        },
        debug_recv => sub {
            my ($cl, $data) = @_;

            $self->debug("Received:\n$data\n") if $DUMP;
        },

        # Generic error handlers
        (
            map {
                my $nam = $_;

                $_ => sub { $self->error("$nam: ".($_[1]->string)); }
            } qw/ roster_error presence_error message_error error session_error iq_auth_error /
        ),
        # ignored: rooster_update, presence_update
    );

    $self->{ext} = {};

    my $disco = $self->{ext}{disco} = AnyEvent::XMPP::Ext::Disco->new;
    $disco->set_identity('bot');
    $cl->add_extension($disco);

    my $version = $self->{ext}{version} = AnyEvent::XMPP::Ext::Version->new;
    $version->set_name("cluebot");
    $version->set_version($VERSION);
    $cl->add_extension($version);

    my $ping = $self->{ext}{ping} = AnyEvent::XMPP::Ext::Ping->new;
    $cl->add_extension($ping);
    $ping->auto_timeout( $self->{ping_timeout} );

    my $receipts = $self->{ext}{receipts} = AnyEvent::XMPP::Ext::Receipts->new( disco => $disco );
    $cl->add_extension($receipts);

    $self->event( connection_setup => $cl );
}

sub _connection_cleanup {
    my $self = shift;

    delete $self->{connection};
    $self->{ext} = {};
}

sub _handle_exception {
    my ($self, $exception, $eventname) = @_;

    $self->error("Exception throw on event $eventname: $exception");
}

sub _handle_plugin_exception {
    my ($self, $plugin, $exception, $eventname) = @_;

    $self->error("Exception throw on plugin $plugin, event $eventname: $exception");
}

=head1 EVENTS

L<Bot::ClueBot> generates the following events.

=head2 connect

Sent when a connection to an XMPP server has been successfully established.

=head2 connection_setup( $cl )

Sent each time a new instance of AnyEvent::XMPP::IM::Connection is created.

Mostly used by plugins to initialize connection-specific options, like XMPP extensions.

The parameter is the newly created L<AnyEvent::XMPP::IM::Connection> object.

=head2 message( $msg )

Event for incoming direct messages. Empty and echo messages don't generate this event.

The parameter is an L<AnyEvent::XMPP::IM::Message> instance.

=head2 fatal, error, warn, log, debug

This events are sent by calls to the methods with the same name on the bot instance.

Generally handled by the bot script, daemon, or plugins to report information via appropriate
channels (eg. STDOUT or a conference room).

With the exception of debug, they all take a message as a parameter. Debug might receive
additional variables to dump with extra information.

=head1 AUTHOR

Quim Rovira, C<< <met at cpan.org> >>

=head1 SUPPORT

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-ClueBot>

=item * GitHub repository

L<http://github.com/qrovira/cluebot/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Quim Rovira.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

=over

=item * L<AnyEvent::XMPP> - AnyEvent modules to handle XMPP connections, on top
of which this modules are built.

=item * L<Bot::Jabbot> - Another jabber bot based on AnyEvent::XMPP.

=back

=cut

1; # End of Bot::ClueBot


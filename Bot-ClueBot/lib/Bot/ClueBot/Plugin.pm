package Bot::ClueBot::Plugin;

use warnings;
use strict;
use 5.10.0;

use base 'Object::Event';

use Scalar::Util qw/weaken/;
use YAML qw/ LoadFile DumpFile /;

=head1 NAME

Bot::ClueBot::Plugin - Base class for Bot::ClueBot plugins

=head1 SYNOPSIS

This class inherits from L<Object::Event> and provides the bare bones for cluebot plugins, including
a default constructor that keeps a weakened reference to the parent bot object, and a couple of
accessors to persist data in an unified way accross plugins.

To get started writing L<Bot::ClueBot> plugins, see L<#CREATTING PLUGINS> below, or check out the
L<Bot::ClueBot::Plugin::Echo> plugin for some sample code.

=head1 CLASS METHODS

=head2 requires()

Returns a list of any other plugins required by this plugin to work.

This is used on loading to try to automatically load any missing plugins.

=cut

sub requires {
    my ($class) = @_;

    return ();
}


=head2 new( $bot, @args )

Constructor for plugin objects, which does some base initializations and finally calls $self->init( @args ), to let
plugins set up their own listeners, etc.

=cut

sub new {
    my ($meta, $bot, @args) = @_;
    my $self = {
        bot => $bot,
    };

    weaken( $self->{bot} );

    bless $self, ref($meta) || $meta;

    $self->init( @args );

    return $self;
}


=head1 METHODS

=head2 init( @args )

Plugin initialization method, to be overriden by plugins.

Plugins should register any required listener on the bot object at this point (See L<Bot::ClueBot#Events>).

=cut

sub init {
    my ($self, @args) = @_;

    $self->bot->warn('Plugin '.__PACKAGE__.' did not implement an init method');
}

=head2 bot()

Just a dummy accessor for the bot object.

=cut

sub bot {
    my $self = shift;

    return $self->{bot};
}

=head2 data()

Accessor for the plugin state data.

If the plugin state has not yet been loaded, it will automatically call L<load_data>.

=cut
sub data {
    my $self = shift;

    return $self->{data} if exists $self->{data};
    return $self->{data} = $self->load_data;
}

=head2 load_data()

Load the state data for this plugin.

Defaults to using the last part of the full module name, on the data_path location specified by the parent bot object.

The serialization format used for the bot is YAML.

=cut
sub load_data {
    my $self = shift;
    my ($name) = reverse split '::', ref $self;

    my $fname = $self->data_file_path;

    unless( $fname ) {
        $self->bot->warn("Cannot find path to file to load plugin data for $name!");
        return;
    }

    my $data = {};

    if( -r $fname ) {
        $data = LoadFile $fname;
        $self->bot->debug("Loaded state for plugin $name from $fname", $data);
    } else {
        $self->bot->debug("No previous state found for $name on $fname");
    }

    return $data;
}

=head2 save_data()

Save the current state data of this plugin.

Right now this needs to be called manually to make sure data is stored.
Failing to do so after modifications will incurr in data loss if the bot is stopped.

=cut
sub save_data {
    my ($self, $data) = @_;
    my ($name) = reverse split '::', ref $self;

    return unless $data //= $self->{data};

    my $fname = $self->data_file_path
        or return;

    DumpFile($fname, $data);

    $self->bot->debug("Saved state for plugin $name to $fname", $data);
}

=head2 data_file_path()

Return the path to the data file for this plugin.

Defaults to the base bot's data_path, followed by the plugin name with a ".yaml" extension

=cut
sub data_file_path {
    my $self = shift;
    my ($name) = reverse split '::', ref $self;

    return unless defined $self->{bot}{data_path};
    my $fname = $self->{bot}{data_path}.$name.".yaml";

    # Hmm, just add the home exception here, no globbing or stupid shit
    $fname =~ s#^~/#$ENV{HOME}/#;

    return $fname;
}

=head1 CREATING PLUGINS

New plugins usually implement the C<init> method to extend the bot functionality,
registering new commands, helpers, and subscribing to events on the bot or other
plugins.

If your plugin depends on another, you can declare that just by returning an array
of dependencies on the L<#requires> method.

Both the base bot object and all plugins end up inheriting from L<Object::Event>
base class, so they all provide means to register to events and to trigger them.
It is encouraged not to pollute the base bot class event space, and instead add
any new events directly on the plugin, to avoid polluting and event name clashes.

=head2 SAMPLE PLUGIN

  package Bot::ClueBot::Plugin::MyPlugin;

  sub requires { qw/ Commands Chatroom / }

  sub init {
    my $self = shift;
    my $args = shift;

    # Provide a rude helper
    $self->bot->helper(
      yell => sub {
        my ($bot, $user, $message) = @_;
        $bot->send_to_user( $user, "OMGWTFBBQ: ".uc( $message )."!!!!" );
      }
    );

    # Listen to events on the Chatroom plugin for messages to us, and react
    $self->plugin('Chatroom')->reg_cb(
      message => sub {
        my ($chatroom, $room, $msg) = @_;

        $self->bot->yell($msg->from, "learn some manners")
            if $msg->body =~ m#(fuck|shit|crap|kurwa)#i;
      }
    );
  }

=cut

1;

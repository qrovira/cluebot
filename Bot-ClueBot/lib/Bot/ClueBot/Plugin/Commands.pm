package Bot::ClueBot::Plugin::Commands;

use base 'Bot::ClueBot::Plugin';

use Sys::Hostname;

use warnings;
use strict;
use 5.10.0;

sub requires { qw/ACL/ }

sub init {
    my $self = shift;

    $self->{commands} = {};
    $self->{started} = time;

    $self->bot->helper(
        command => sub {
            my $bot = shift;

            while( @_ ) {
                my $command = shift;
                my $config = ref($_[0]) eq 'HASH' ? shift : {};
                my $cb = shift;

                $config->{category} //= "General";
                $config->{params} //= [];

                ($config->{argline}, $config->{usage}) = $self->_params_to_argline( $command, @{ $config->{params} } )
                    if( @{ $config->{params} } && !defined($config->{argline}) );

                $bot->debug("Registering command $command", $config);
                $self->{commands}{$command} = { %$config, cb => $cb };
            }
        },
        handle_command => sub {
            my ($bot, $command, $context) = @_;
            my $config = $self->{commands}{$command};

            unless( $config ) {
                my $msg = "Unrecognized command $command";
                $self->bot->log($msg);
                $context->reply($msg);
                return;
            }

            if( $config->{acl} && !$context->auth( $config->{acl} ) ) {
                my $msg = "Not allowed to execute command $command";
                $self->bot->log($msg);
                $context->reply($msg);
                return;
            }

            if( my @errors = $context->validate_params( $config ) ) {
                my $msg = "Bad parameters for command $command:\n".
                    join "\n", map "\t- $_", @errors;
                $self->bot->log($msg);
                $context->reply($msg);
                return;
            }

            $self->bot->debug("Command call", { command => $command, context => $context });
            $config->{cb}->($context);
        }
    );

    $self->bot->reg_cb(
        message => sub {
            my ($bot, $msg) = @_;
            my $body = $msg->body;

            # Hmmm... grrr...
            $body =~ s#^\s*<Gaim-Encryption Capable>##;

            # Match command
            return unless $body =~ qr#^(?<command>\w+)(?:\s+(?<argline>.*))?$#;

            my $context = Bot::ClueBot::Plugin::Commands::Context::Message->new(
                bot     => $bot,
                message => $msg,
                argline => $+{argline},
            );

            $bot->handle_command( $+{command}, $context );
        },
    );

    $self->bot->command(
        help => {
            help => "Display this help message",
            params => [
                command => {
                    help => "Command for which you want to see additional help",
                    validation => sub { !!$self->{commands}{$_[0]} },
                }
            ]
        } => \&_command_help,

        uptime => {
            help => "Tell number of seconds this bot has been running",
            public => 1,
        } => \&_command_uptime,

        flush_state => {
            help => "Save plugin state information to disk.",
            params => [
                plugin => {
                    help => "Name of the plugin to flush state to disk. If not specified, all plugins are flushed.",
                    validation => sub { !!$self->bot->plugin($_[0]) },
                },
            ],
            category => "Plugins",
        } => \&_command_flush_state,

        show_state => {
            help => "Show plugin state information",
            params => [
                plugin => {
                    help => "Optional name of the plugin to show state of. If not specified, all plugins are shown.",
                    validation => sub { !!$self->bot->plugin($_[0]) },
                },
            ],
            category => "Plugins",
        } => \&_command_show_state,
    );

}


sub _command_help {
    my ($context) = @_;
    my $self = $context->{bot}->plugin('Commands');

    if( $context->{params}{command} ) {
        my $cfg = $self->{commands}{$context->{params}{command}};

        if( $cfg ) {
            my $msg = "Help for $context->{params}{command}:";
            $msg .= "\n".$cfg->{help} if $cfg->{help};
            $msg .= "\nUsage: ".$cfg->{usage} if $cfg->{usage};

            my @params = @{ $cfg->{params} // [] };
            if( @params ) {
                $msg .= "\nParams:";
                while ( @params ) {
                    my $param = shift @params;
                    my $def = shift @params;

                    $msg .= "\n\t- $param";
                    $msg .= ": ".$def->{help} if $def->{help};
                    $msg .= " (optional)" unless $def->{required};
                    $msg .= " (default ".$def->{default}.")" if defined $def->{default};
                }
            }

            $context->reply( $msg );
        } else {
            $context->reply("Unknown command '$context->{params}{command}'");
        }
    } else {
        # Not using make_reply since this could be quite verbose
        my $last_category = "";
        my %acl_check_cache;
        $context->reply(
            "Available commands:\n".
            join "\n", map {
                my $cfg = $self->{commands}{$_};
                my $prefix = "";

                if($cfg->{category} ne $last_category) {
                    $prefix = "\t$cfg->{category}\n";
                    $last_category = $cfg->{category};
                }

                "$prefix\t\t$_".
                ( defined $cfg->{help} ? " - ".$cfg->{help} : "" ).
                ( defined $cfg->{usage} ? "\n\t\t\tUsage: ".$cfg->{usage} : "" )
            } sort {
                $self->{commands}{$a}{category} cmp $self->{commands}{$b}{category} ||
                $a cmp $b
            } grep {
                $self->{commands}{$_}{acl} ?
                    $acl_check_cache{$self->{commands}{$_}{acl}} //= $context->{bot}->auth( $self->{commands}{$_}{acl}, $context->{source_user} ) :
                    1
            } keys %{$self->{commands}}
        );
    }
}

sub _command_uptime {
    my ($context) = @_;
    my $self = $context->{bot}->plugin('Commands');

    $context->reply("Running for ".(time - $self->{started})." seconds, from ".hostname." PID $$");
}

sub _command_flush_state {
    my ($context) = @_;
    my $self = $context->{bot}->plugin('Commands');

    foreach my $plugin_name ( $context->{params}{plugin} // $context->{bot}->plugins ) {
        my $plugin = $context->{bot}->plugin($plugin_name);
        $plugin->save_data;
        $context->reply("Flushed state of plugin $plugin_name to disk");
    }
}

sub _command_show_state {
    my ($context) = @_;
    my $self = $context->{bot}->plugin('Commands');

    foreach my $plugin_name ( $context->{params}{plugin} // $context->{bot}->plugins ) {
        my $plugin = $context->{bot}->plugin($plugin_name);
        $context->reply("State data for plugin $plugin_name:");
        $context->reply($plugin->data);
    }
}



sub _params_to_argline {
    my ($self, $command, @params) = @_;
    my ($argline, $help) = ("","");

    my $nparams = 0;
    @params = reverse @params;
    while( @params ) {
        my $def = shift @params;
        my $param = shift @params;
        my $validation = $def->{validation};

        my $check =
            (ref($validation) eq 'Regexp') ?
            qr#(?<$param>$validation)# :
            (ref($validation) eq 'ARRAY') ?
            qr#(?<$param>@{[ join "|", @$validation ]})# :
            qr#(?<$param>[^\s]+)#;

        if($def->{required}) {
            if( $nparams ) {
                $argline = qr#\s+$check$argline#;
                $help = "<$param> $help";
            } else {
                $argline = qr#\s+$check#;
                $help = "<$param>";
            }
        } else {
            if( $nparams ) {
                $argline = qr#(?:\s+$check$argline)?#;
                $help = "[<$param> $help]";
            } else {
                $argline = qr#(?:\s+$check)?#;
                $help = "[<$param>]";
            }
        }

        $nparams++;
    }

    return ($argline, "$command $help");
}



package Bot::ClueBot::Plugin::Commands::Context;

use Scalar::Util qw/ weaken /;

sub new {
    my ($proto, %args) = @_;
    my $self = {
        bot     => delete $args{bot},
        argline => '',
        params  => {},
        %args,
    };

    weaken $self->{bot};

    bless $self, ref($proto) || $proto;

    return $self;
}

sub reply         { die "Command reply method not implemented"; }
sub reply_private { die "Command private reply method not implemented"; }

sub auth {
    my ($self, $acl) = @_;

    return $self->{bot}->auth( $acl, $self->{source_user} );
}

sub validate_params {
    my ($self, $config) = @_;
    my @errors = ();

    $self->{params} = { %+ }
        if( length($self->{argline}) && " $self->{argline}" =~ m/^$config->{argline}$/ );

    my @params = @{ $config->{params} // [] };
    while( @params ) {
        my $param = shift @params;
        my $def = shift @params;
        my $val = $self->{params}{$param} // $def->{default};

        unless( defined($val) ) {
            push @errors, "$param is required"
                if $def->{required};
            next;
        }

        my $validation = $def->{validation};
        if( defined $validation ) {
            if( ref($validation) eq 'CODE' ) {
                push @errors, "Invalid value '$val' for param '$param'"
                    unless $validation->($val);
            }
            elsif( ref($validation) eq 'ARRAY' ) {
                push @errors, "Invalid value '$val' for param '$param' (Valid options: ".join(",",@{ $def->{validation} } ).")"
                    unless !grep { $val eq $_ } @{ $def->{validation} };
            }
            elsif( ref($validation) eq 'Regexp' ) {
                push @errors, "Invalid value '$val' for param '$param'"
                    unless $val =~ $def->{validation};
            }
        }
    }

    return @errors;
}


package Bot::ClueBot::Plugin::Commands::Context::Message;

use base 'Bot::ClueBot::Plugin::Commands::Context';

use YAML;

sub new {
    my ($proto, %args) = @_;
    my $msg = $args{message};

    die "Invalid source message specified"
        unless $msg && ref($msg) && $msg->isa('AnyEvent::XMPP::IM::Message');

    my $self = $proto->SUPER::new(
        source      => $msg->type,
        source_jid  => $msg->from,
        source_user => $msg->from,
        %args,
    );

    return $self;
}

sub reply {
    my ($self, $data) = @_;
    my $reply = $self->{message}->make_reply;

    $reply->add_body( ref($data) ? Dump($data) : $data );
    $reply->send;
}

sub private_reply { shift->reply(@_); }

1;

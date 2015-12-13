package Bot::ClueBot::Plugin::Run;

use base 'Bot::ClueBot::Plugin';

use AnyEvent::Open3::Simple;

use warnings;
use strict;
use utf8;
use 5.10.0;

our $VERSION = '0.01';

=head1 NAME

Bot::ClueBot::Plugin::Run - Shell command execution plugin for Bot::ClueBot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Provides shell command execution features to Bot::ClueBot.

This plugin is restricted to the 'Run' ACL group.

=head1 OPTIONS

=over

=item commands

Hash that maps command aliases to the actual shell commands executed.

Values can either be strings specifying the full cmdline, or a hash specifying
any of the following options:

=over

=item cmdline

Full cmdline to be executed, either a single string, or an array consisting of the path to executable and the arguments.

=item acl

Access control list to check.

=back

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

=head1 EVENTS

=over

=item

=back

=cut


sub requires { qw/ Commands / }

sub init {
    my $self = shift;
    my $args = {
        commands => {},
        %{ shift // {} },
    };

    $self->bot->register_acl("run");

    $self->bot->helper(
        run_command => sub {
            my ($bot, $arg1 ) = @_;

            ...
        },
    );

    $self->bot->command(
        list_commands => {
            help => "List all available commands",
            category => "Run",
            acl => 'run',
        } => sub {
            my ($context) = @_;

            $context->reply(
                "Available commands:\n".
                join "\n",
                map {
                    "\t- $_: ". (
                        ref($args->{commands}{$_}) eq 'HASH' ?
                            ( $args->{commands}{$_}{description} // $args->{commands}{$_}{cmdline} ) :
                            $args->{commands}{$_}
                    )
                }
                grep {
                    !ref($args->{commands}{$_}) ||
                    !length($args->{commands}{$_}{acl}) ||
                    $self->bot->auth( $args->{commands}{$_}{acl}, $context->{source_user} )
                }
                keys( %{ $args->{commands} } )
            );
        },
        run => {
            help => "Run command",
            params => [
                command => {
                    help => "Command to run",
                    required => 1,
                    validation => sub { !!$args->{commands}{$_[0]} },
                }
            ],
            category => "Run",
            acl => 'run',
        } => sub {
            my ($context) = @_;
            my $cmd = $context->{params}{command};
            my $info = ref($args->{commands}{$cmd}) ?
                $args->{commands}{$cmd} :
                { cmdline => $args->{commands}{$cmd} };

            if( $info->{acl} && !$context->auth( $info->{acl} ) ) {
                $context->reply("Not allowed to run command $cmd.");
                return;
            }

            my $ipc = $self->_ipc($cmd, $context);

            $ipc->run( ref($info->{cmdline}) ? @{ $info->{cmdline} } : $info->{cmdline} );
        },
    );
}


sub _ipc {
    my ($self, $cmd, $context) = @_;

    AnyEvent::Open3::Simple->new(
        on_start => sub {
            my ($open3) = @_;
            $context->reply($cmd." (".$open3->pid.") Started");
        },
        on_stdout => sub {
            my ($open3, $line) = @_;
            $context->reply($cmd." (".$open3->pid.") out: ".$line);
        },
        on_stderr => sub {
            my ($open3, $line) = @_;
            $context->reply($cmd." (".$open3->pid.") err: ".$line);
        },
        on_exit => sub {
            my ($open3, $exit_val, $signal) = @_;
            $context->reply($cmd." (".$open3->pid.") Finished (status = ".$exit_val.")");
        },
        on_error => sub {
            my ($error) = @_;
            $context->reply($cmd." error: ".$error);
        },
    );
}


1;

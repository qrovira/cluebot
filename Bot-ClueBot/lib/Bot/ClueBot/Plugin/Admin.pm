package Bot::ClueBot::Plugin::Admin;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use 5.10.0;

sub requires { qw/Commands/ }

sub init {
    my $self = shift;
    my $args = {
        %{ shift // {} },
    };

    $self->bot->register_acl("admin");

    $self->bot->command(
        whisper => {
            help => "Send a message to given user.",
            params => [
                user => {
                    help => "User to send a message to (can be either an email address or a full JID)",
                    validation => qr#[^\s]+\@[^\s]+#,
                    required => 1,
                },
                message => {
                    help => "Message to send",
                    validation => qr#.*#,
                    required => 1,
                },
            ],
            acl => "admin",
            category => "Admin",
        } => sub {
            my ($context) = @_;

            $self->bot->log(
                $context->{source_jid}." asked me to whisper to ".
                $context->{params}{user}.": ".$context->{params}{message}
            );
            $self->bot->send_to_user( $context->{params}{user}, $context->{params}{message} );
        },

        stop => {
            help => "Stop the bot process",
            acl => "admin",
            category => "Admin",
        } => sub {
            my ($context) = @_;
            $self->bot->log("Received stop request from ".$context->{source_jid});
            $context->reply("Die with honor!");
            $self->{stop_cv} = AnyEvent->timer(
                after => 1,
                cb => sub { $self->bot->disconnect; }
            );
        },

        acl_add => {
            help => "Add user to a given ACL list",
            params => [
                acl_name => {
                    help => "Name of the ACL to add the user to",
                    required => 1,
                },
                user => {
                    help => "User identifier (eg. email address)",
                    required => 1,
                },
            ],
            acl => "admin",
            category => "Admin",
        } => sub {
            my ($context) = @_;
            my $acl_name = $context->{params}{acl_name};
            my $acl = $context->{bot}->plugin('ACL')->data->{acls}{$acl_name};
            my $user = $context->{params}{user};

            unless( $acl ) {
                $context->reply("No such ACL: $acl_name.");
                return;
            }

            if( exists $acl->{$user} ) {
                $context->reply("User $user is already on acl $acl_name.");
                return;
            }

            $acl->{$context->{params}{user}} = 1;
            $context->reply("Added user $user to acl $acl_name.");

            $context->{bot}->plugin('ACL')->save_data;
        },

        acl_remove => {
            help => "Remove user to a given ACL list",
            params => [
                acl_name => {
                    help => "Name of the ACL to remove the user from",
                    required => 1,
                },
                user => {
                    help => "User identifier (eg. email address)",
                    required => 1,
                }
            ],
            acl => "admin",
            category => "Admin",
        } => sub {
            my ($context) = @_;
            my $acl_name = $context->{params}{acl_name};
            my $acl = $context->{bot}->plugin('ACL')->data->{acls}{$acl_name};
            my $user = $context->{params}{user};

            unless( $acl ) {
                $context->reply("No such ACL: $acl_name.");
                return;
            }

            unless( exists $acl->{$user} ) {
                $context->reply("User $user is not on acl $acl_name.");
                return;
            }

            delete $acl->{$context->{params}{user}};
            $context->reply("Removed user $user from acl $acl_name.");

            $context->{bot}->plugin('ACL')->save_data;
        },

        acl_show => {
            help => "Show all ACL information",
            category => "Admin",
        } => sub {
            my ($context) = @_;

            $context->reply($context->{bot}->plugin('ACL')->freeze_data);
        }
    );

}


1;

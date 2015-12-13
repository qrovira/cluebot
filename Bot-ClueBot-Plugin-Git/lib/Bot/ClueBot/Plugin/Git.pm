package Bot::ClueBot::Plugin::Git;

use base 'Bot::ClueBot::Plugin';

use warnings;
use strict;
use utf8;
use 5.10.0;

use List::Util qw/ min /;
use File::Spec;
use Try::Tiny;
use AnyEvent::Git::Wrapper;

our $VERSION = '0.02';

=head1 NAME

Bot::ClueBot::Plugin::Git - Git plugin for Bot::ClueBot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Provides Git features to Bot::ClueBot

=head1 OPTIONS

=over

=item option1

Descriptiton of option1

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


sub requires { qw/Commands ACL/ }

sub init {
    my $self = shift;
    my $args = {
        log_max_commits => 10,
        %{ shift // {} },
    };

    $self->bot->register_acl( "git" );

    if( my $root = delete $args->{gitroot} ) {
        if( -d $root ) {
            opendir( my $dh, $root );
            my @dirs = grep /^(?!\.)/, readdir $dh;
            closedir $dh;

            $self->register_repository( $_ => File::Spec->catfile( $root, $_ )  )
                foreach @dirs;
        }
        else {
            $self->bot->warn("Invalid git root path '$root'");
        }
    }

    if( my $repos = delete $args->{ repos } ) {
        if( ref $args->{repos} eq "ARRAY" ) {
            $self->register_repository( $_ )
                foreach @$repos;
        } else {
            $self->register_repository( $_, $repos->{$_} )
                foreach keys %$repos;
        }
    }

    $self->bot->helper(
        repository => sub {
            my ($bot, $name ) = @_;

            return $self->{repos}{$name};
        },
    );

    $self->bot->command(
        git_repos => {
            help => "Display a list of known repositories",
            category => "Git",
            acl => "git",
        } => sub {
            my ($context) = @_;

            $context->reply(
                join "\n",
                    "Known repositories:",
                    keys %{ $self->{repos} }
            );
        },

        git_log => {
            help => "Display the recent commit log for a repository",
            params => [
                repo => {
                    help => "Repository name",
                    required => 1,
                },
                ref => {
                    help => "Commit reference (eg. sha-1) to log from",
                },
                num => {
                    help=> "Number of commits to display (optional, defaults to $args->{log_max_commits})",
                    validation => qr#[0-9]+#,
                },
            ],
            category => "Git",
            acl => "git",
        } => sub {
            my ($context) = @_;
            my $repo = $self->{repos}{$context->{params}{repo}};
            my $ref = $context->{params}{ref} // "HEAD";
            my $num = min( $args->{log_max_commits}, $context->{params}{num} // () );

            unless( $repo ) {
                $context->reply("Invalid repository $context->{params}{repo}");
                return;
            }

            $context->reply(
                join "\n",
                    "Commit log for $context->{params}{repo} ($ref), up to $num commits:",
                    map {
                        my @msg = split /\n/, $_->{message};

                        $_->{id}." ".$msg[0];
                    }
                    $repo->log( $ref, { n => " $num" } ) # This needs space padding to avoid the special case with '1' being ommited
            );
        },
    );
}


sub register_repository {
    my $self = shift;
    my $name = shift;
    my $path = shift // $name;

    my $g = AnyEvent::Git::Wrapper->new( $path );

    try {
        my ($head) = $g->log({ n => " 1" });
        $self->{repos}{$name} = $g;
        $self->bot->log("Registered git repository $name on $path, head is ".$head->{id});
    } catch {
        $self->bot->warn("Failed to register git repository $name on $path", (ref($_) ? {%{$_}} : { msg => $_ }) );
    };
}



1;

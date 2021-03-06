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

Bot::ClueBot::Plugin::Git - ClueBot plugin that provides Git integration

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This plugin provides access to Git local git repositories, so users can request
information via commands, and other plugins can get repository handles via a
helper.

=head1 ACL

Access to this plugin's functionality requires C<git> ACL membership.

=head1 OPTIONS

=over

=item gitroot

Base directory for git repositories. All subdirectories will be checked at start
time, when checking for repos.

=item repos

Repositories to register.

It can either be an array of paths to the repositories, or a hash that maps repository
names to their paths.

=item log_max_commits

Maximum number of commits that can be returned when fetching information via commands.

=back

=head1 HELPERS

=over

=item repository( $name )

Returns the AnyEvent::Git::Wrapper object for the given reposiroty alias.

=back

=head1 COMMANDS

=over

=item git_repos

Display a list of known repositories

=item git_log $repo [$ref [$num] ]

Display the commig short log for a given repository

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

            foreach my $repo (@dirs) {
                my $fdir = File::Spec->catfile( $root, $repo );
                next unless -d $fdir;
                $self->register_repository( $repo => $fdir  );
            }
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

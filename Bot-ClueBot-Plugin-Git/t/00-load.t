#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bot::ClueBot::Plugin::Git' ) || print "Bail out!\n";
}

diag( "Testing Bot::ClueBot::Plugin::Git $Bot::ClueBot::Plugin::Git::VERSION, Perl $], $^X" );

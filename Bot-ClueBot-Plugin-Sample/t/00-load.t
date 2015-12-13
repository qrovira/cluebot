#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bot::ClueBot::Plugin::Sample' ) || print "Bail out!\n";
}

diag( "Testing Bot::ClueBot::Plugin::Sample $Bot::ClueBot::Plugin::Sample::VERSION, Perl $], $^X" );

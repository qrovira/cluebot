#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bot::ClueBot::Plugin::HTTPD' ) || print "Bail out!\n";
}

diag( "Testing Bot::ClueBot::Plugin::HTTPD $Bot::ClueBot::Plugin::HTTPD::VERSION, Perl $], $^X" );

#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;


plan tests => 9;


BEGIN {
    use_ok('Bot::ClueBot') and
    use_ok('Bot::ClueBot::Plugin') and
    use_ok('Bot::ClueBot::Plugin::DefaultHelpers') and
    use_ok('Bot::ClueBot::Plugin::Echo') and
    use_ok('Bot::ClueBot::Plugin::Commands') and
    use_ok('Bot::ClueBot::Plugin::Chatroom') and
    use_ok('Bot::ClueBot::Plugin::Admin') and
    use_ok('Bot::ClueBot::Plugin::ACL') and
    use_ok('Bot::ClueBot::Plugin::LogToRoom') and
        1 or print "Bail out!\n";
}

diag( "Testing Bot::ClueBot $Bot::ClueBot::VERSION, Perl $], $^X" );

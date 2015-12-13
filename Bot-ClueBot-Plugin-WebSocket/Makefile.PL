use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bot::ClueBot::Plugin::WebSocket',
    AUTHOR           => q{Quim Rovira <met@cpan.org>},
    VERSION_FROM     => 'lib/Bot/ClueBot/Plugin/WebSocket.pm',
    ABSTRACT_FROM    => 'lib/Bot/ClueBot/Plugin/WebSocket.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Bot::ClueBot'                => '0.01',
        'AnyEvent::WebSocket::Client' => '0.27',
        'AnyEvent::WebSocket::Server' => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-ClueBot-Plugin-WebSocket-*' },
);

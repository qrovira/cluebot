use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bot::ClueBot::Plugin::HTTPD',
    AUTHOR           => q{Quim Rovira <met@cpan.org>},
    VERSION_FROM     => 'lib/Bot/ClueBot/Plugin/HTTPD.pm',
    ABSTRACT_FROM    => 'lib/Bot/ClueBot/Plugin/HTTPD.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Bot::ClueBot' => "0.01",
        'AnyEvent::HTTP'              => '2.21',
        'AnyEvent::HTTPD'             => '0.93',
        'Bot::ClueBot::Plugin::WebTokens' => "0.01",
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-ClueBot-Plugin-HTTPD-*' },
);

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bot::ClueBot::Plugin::WebTokens',
    AUTHOR           => q{Quim Rovira <met@cpan.org>},
    VERSION_FROM     => 'lib/Bot/ClueBot/Plugin/WebTokens.pm',
    ABSTRACT_FROM    => 'lib/Bot/ClueBot/Plugin/WebTokens.pm',
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
        'JSON::WebToken' => "0.10",
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-ClueBot-Plugin-WebTokens-*' },
);

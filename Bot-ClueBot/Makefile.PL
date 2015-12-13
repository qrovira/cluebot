use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bot::ClueBot',
    AUTHOR           => q{Quim Rovira <met@cpan.org>},
    VERSION_FROM     => 'lib/Bot/ClueBot.pm',
    ABSTRACT_FROM    => 'lib/Bot/ClueBot.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    EXE_FILES => [
        'bin/cluebot'   
    ],
    PREREQ_PM => {
        'YAML'                        => '1.15',
        'AnyEvent'                    => '7.07',
        'AnyEvent::XMPP'              => '0.54',
        'Term::ReadPassword'          => '0.11',
        'Sys::Hostname'               => '1.18',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bot-ClueBot-*' },
);

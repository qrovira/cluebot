use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $plugin_name = "Git";

WriteMakefile(
    NAME             => "Bot::ClueBot::Plugin::$plugin_name",
    AUTHOR           => q{Quim Rovira <met@cpan.org>},
    VERSION_FROM     => "lib/Bot/ClueBot/Plugin/$plugin_name.pm",
    ABSTRACT_FROM    => "lib/Bot/ClueBot/Plugin/$plugin_name.pm",
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
        'Bot::ClueBot'           => "0.02",
        'AnyEvent::Git::Wrapper' => '0.07',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => "Bot-ClueBot-Plugin-$plugin_name-*" },
);

use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.3 2002/08/26 02:40:25 moseley Exp $

WriteMakefile(
    NAME          => 'Text::Aspell',
    VERSION_FROM  => 'Aspell.pm',
    LIBS          => ['-laspell'],
    XSPROTOARG    => '-noprototypes',
    PREREQ_PM     => {
        'Test::More'    => 0,
    },
);

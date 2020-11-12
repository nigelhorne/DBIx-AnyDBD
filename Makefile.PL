use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::AnyDBD',
    'VERSION_FROM' => 'AnyDBD.pm', # finds $VERSION
     META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources => {
                repository => {
                        type => 'git',
                        url => 'git://github.com/nigelhorne/DBIx-AnyDBD.git',
                        web => 'https://github.com/nigelhorne/DBIx-AnyDBD',
                },
        },
    },
);

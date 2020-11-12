use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'	=> 'DBIx::AnyDBD',
	'ABSTRACT_FROM' => 'lib/DBIx/AnyDBD.pm',
	'VERSION_FROM' => 'lib/DBIx/AnyDBD.pm', # finds $VERSION
	'PREREQ_PM' => {
		'DBI' => 0,
	},
);

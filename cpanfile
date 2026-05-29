# Generated from Makefile.PL using makefilepl2cpanfile

requires 'DBI';

on 'test' => sub {
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::Needs';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};

package DBIx::AnyDBD;
use DBI;
use strict;
use vars qw/$AUTOLOAD $VERSION/;

$VERSION = '0.95';

sub new {
	my $class = shift;
	my %args = @_;
	my $dbh = DBI->connect(
			$args{dsn}, 
			$args{user}, 
			$args{pass},
			($args{attr} ||
				{
					AutoCommit => 0,
					PrintError => 0,
					RaiseError => 1,
				})
			);
	die "Can't connect: ", DBI->errstr unless $dbh;
	my $package = $args{package} || __PACKAGE__;
	bless { package => $package, dbh => $dbh }, $class;
}

sub connect {
	my $class = shift;
	my ($dsn, $user, $pass, $args, $package) = @_;
	$dsn ||= $ENV{DBI_DSN} || $ENV{DBI_DBNAME} || '';
	my $dbh = DBI->connect($dsn, $user, $pass, $args);
	return undef unless $dbh;
	$package ||= __PACKAGE__;
	bless { package => $package, dbh => $dbh }, $class;
}

sub get_dbh {
	my $self = shift;
	# maybe add code here to check connection status.
	# or maybe add check once every 10 get_dbh's...
	return $self->{dbh};
}

sub DESTROY {
	my $self = shift;
	$self->{dbh}->disconnect;
}

sub AUTOLOAD {
	my $self = shift;
	my (@params) = @_;
	no strict ('refs', 'subs');
	if ($AUTOLOAD =~ /.*::db_(\w+)$/) {
		my $method = $1;
		my $driver = $self->{dbh}->{Driver}->{Name};
		my $dir;
		($dir = $self->{package}) =~ s/::/\//g;
		require "$dir/$driver.pm";
		my $newsub = \&{"$self->{package}::$driver\::$method"};
		if (defined &$newsub) {
			*{$AUTOLOAD} = $newsub;
			&{"$self->{package}::$driver\::$method"}($self, @params);
		}
		else {
			require "$dir/Default.pm";
			$newsub = \&{"$self->{package}::Default\::$method"};
			if (defined &$newsub) {
				*{$AUTOLOAD} = $newsub;
				&{"$self->{package}::Default\::$method"}($self, @params);
			}
			else {
				die "Method $method not found in DB Dependant classes\n";
			}
		}			
	}
	else {
		die "No such method $AUTOLOAD\n";
	}
}

1;

__END__

=head1 NAME

DBIx::AnyDBD - DBD independant class

=head1 DESCRIPTION

This class provides application developers with an abstraction class
a level away from DBI, that allows them to write an application that
works on multiple database platforms. The idea isn't to take away the
responsibility for coding different SQL on different platforms, but
to simply provide a platform that uses the right class at the right
time for whatever DB is currently in use.

=head1 SYNOPSIS

	use DBIx::AnyDBD;
	
	my $db = DBIx::AnyDBD->connect("dbi:Oracle:sid1", 
		"user", "pass", {}, "MyClass");

	my $foo = $db->db_foo;
	my $blee = $db->db_blee;

That doesn't really tell you much... Because you have to implement a
bit more than that. Underneath you have to have a module 
MyClass::Oracle that has methods foo() and blee in it. If those
methods don't exist in MyClass::Oracle, it will check in MyClass::Default,
allowing you to implement code that doesn't need to be driver
dependant in the same module. The foo() and blee() methods will recieve
the DBIx::AnyDBD instance as thier first parameter, and any parameters
you pass just go as parameters.

=head1 Implementation

Underneath it's all implemented using clever use of AUTOLOAD, but don't
fret - the AUTOLOAD overhead only occurs the first time you use the method,
thereafter if assigns the appropriate method to the *{$AUTOLOAD} glob. I
borrowed that code from Object Oriented Perl, so thanks go to Damian Conway
for that. The subclass it uses is "$package::" . $dbh->{Driver}->{Name}, so
make sure you check with whichever driver you're using for what that returns,
it's been tested with Oracle and Sybase (which use the driver names "Oracle"
and "Sybase" respectively.

=head1 API

=head2 new( ... )

	dsn => $dsn, 
	user => $user, 
	pass => $pass, 
	attr => $attr,
	package => $package

new() is a named parameter call that connects and creates a new db object
for your use. The named parameters are dsn, user, pass, attr and package.
The first 4 are just the parameters passed to DBI->connect, and package
contains the package prefix for your database dependant modules, for example,
if package was "MyPackage", the AUTOLOADer would look for 
MyPackage::Oracle::func, and then MyPackage::Default::func.

If attr is undefined then the default attributes are:

	AutoCommit => 0
	PrintError => 0
	RaiseError => 1

So be aware if you don't want your application dying to either eval{} all
db sections and catch the exception, or pass in a different attr parameter.

=head2 connect($dsn, $user, $pass, $attr, $package)

connect() is very similar to DBI->connect, taking exactly the same first
4 parameters. The 5th parameter is the package prefix, as above.

connect() doesn't try and default attributes for you if you don't pass them.

=head2 $db->get_dbh()

This method is mainly for the DB dependant modules to use, it returns the
underlying DBI database handle. There will probably have code added here
to check the db is still connected, so it may be wise to always use this
method rather than trying to retrieve $self->{dbh} directly.

=head1 LICENCE

This module is free software, and you may distribute it under the same 
terms as Perl itself.

=head1 SUPPORT

Commercial support for this module is available on a pay per incident
basis from Fastnet Software Ltd. Contact matt@sergeant.org for further
details.

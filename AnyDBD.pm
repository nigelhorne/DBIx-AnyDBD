# $Id: AnyDBD.pm,v 1.6 2000/09/15 15:51:48 matt Exp $

package DBIx::AnyDBD;
use DBI;
use strict;
use vars qw/$AUTOLOAD $VERSION/;

$VERSION = '1.97';

sub new {
    my $class = shift;
    my %args = @_;
    my $dbh = DBI->connect(
            $args{dsn}, 
            $args{user}, 
            $args{pass},
            ($args{attr} ||
                {
                    AutoCommit => 1,
                    PrintError => 0,
                    RaiseError => 1,
                })
            );
    die "Can't connect: ", DBI->errstr unless $dbh;
    my $package = $args{'package'} || __PACKAGE__;
    my $self = bless { 'package' => $package, dbh => $dbh }, $class;
    $self->rebless;
    return $self;
}

sub connect {
    my $class = shift;
    my ($dsn, $user, $pass, $args, $package) = @_;
    $dsn ||= $ENV{DBI_DSN} || $ENV{DBI_DBNAME} || '';
    my $dbh = DBI->connect($dsn, $user, $pass, $args);
    return undef unless $dbh;
    $package ||= __PACKAGE__;
    my $self = bless { 'package' => $package, 'dbh' => $dbh }, $class;
    $self->rebless;
    return $self;
}

sub rebless {
    my $self = shift;
    my $driver = ucfirst($self->{dbh}->{Driver}->{Name});
    my $class = $self->{'package'};
    my ($odbc, $ado) = ($driver eq 'ODBC', $driver eq 'ADO');
    if ($odbc || $ado) {
        my $name;
        
        if ($odbc) {
            no strict;
            $name = $self->{dbh}->func(17, GetInfo);
        }
        elsif ($ado) {
            $name = $self->{dbh}->{ado_conn}->Properties->Item('DBMS Name')->Value;
        } 
        else {
            die "Can't determine driver name!\n";
        }
        
        if ($name eq 'Microsoft SQL Server') {
            $driver = 'MSSQL';
        }
        elsif ($name eq 'SQL Server') {
            $driver = 'Sybase';
        }
        elsif ($name =~ /Oracle/) {
            $driver = 'Oracle';
        }
#             elsif ($name eq 'ACCESS') {
#                   $driver = 'Access';
#             }
#             elsif ($name eq 'Informix') {
#                   $driver = 'Informix'; # caught by "else" condition below
#             }
        elsif ($name eq 'Adaptive Server Anywhere') {
            $driver = 'ASAny';
        }
        else {  # this should catch Access and Informix
            $driver = lc($name);
            $driver =~ s/\b(\w)/uc($1)/eg;
            $driver =~ s/\s+/_/g;
        }
    }
    
    no strict 'refs';
    my $dir;
    ($dir = $self->{package}) =~ s/::/\//g;
    load_module("$dir/Default.pm") or die "Cannot find Default.pm module!";

    if (!load_module("$dir/$driver.pm")) {
        # no package for driver - use Default instead
        bless $self, "${class}::Default";
        # make Default -> DBIx::AnyDBD hierarchy
        @{"${class}::Default::ISA"} = ('DBIx::AnyDBD');
    }
    else {
        # package OK...
        
        bless $self, "${class}::${driver}";
        
        if ($ado) {
            if (load_module("$dir/ADO.pm")) {
                if (!load_module("$dir/ODBC.pm")) {
                    @{"${class}::${driver}::ISA"} = ("${class}::ADO");
                    @{"${class}::ADO::ISA"} = ("${class}::Default");
                }
                else {
                    @{"${class}::${driver}::ISA"} = ("${class}::ADO");
                    @{"${class}::ADO::ISA"} = ("${class}::ODBC");
                    @{"${class}::ODBC::ISA"} = ("${class}::Default");
                }
                return;
            }
        }
        
        if ($odbc) {
            if (load_module("$dir/ODBC.pm")) {
                @{"${class}::${driver}::ISA"} = ("${class}::ODBC");
                @{"${class}::ODBC::ISA"} = ("${class}::Default");
                return;
            }
        }
        
        # make Default -> DBIx::AnyDBD hierarchy
        @{"${class}::Default::ISA"} = ('DBIx::AnyDBD');
        # make Driver -> Default hierarchy
        @{"${class}::${driver}::ISA"} = ("${class}::Default");
    }
    
}

sub load_module {
    my $module = shift;
    
    eval {
        require $module;
    };
    if ($@) {
        if ($@ =~ /^Can't locate $module in @INC/) {
            return 0;
        }
        else {
            die $@;
        }
    }
    
    return 1;
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
    my $func = $AUTOLOAD;
    $func =~ s/.*:://;
    no strict 'refs';
    *{$AUTOLOAD} = sub { shift->get_dbh->$func(@_); };
    return $self->get_dbh->$func(@_);
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

    my $foo = $db->foo;
    my $blee = $db->blee;

That doesn't really tell you much... Because you have to implement a
bit more than that. Underneath you have to have a module 
MyClass::Oracle that has methods foo() and blee in it. If those
methods don't exist in MyClass::Oracle, it will check in MyClass::Default,
allowing you to implement code that doesn't need to be driver
dependant in the same module. The foo() and blee() methods will recieve
the DBIx::AnyDBD instance as thier first parameter, and any parameters
you pass just go as parameters.

See the example Default.pm and Sybase.pm classes in the AnyDBD directory
for an example.

=head1 Implementation

Underneath it's all implemented using the ISA hierarchy, which is modified 
when you connect to your database. The inheritance tree ensures that the
right functions get called at the right time. There is also an AUTOLOADer
that steps in if the function doesn't exist and tries to call the function
on the database handle (i.e. in the DBI class). The sub-classing uses
C<ucfirst($dbh->{Driver}->{Name})> (along with some clever fiddling for
ODBC and ADO) to get the super-class, so if you don't know what to name
your class (see the list below first) then check that.

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
MyPackage::Oracle::func, and then MyPackage::Default::func. Beware that the
DBD driver will be ucfirst'ed, because lower case package names are reserved
as pragmas in perl. See the known DBD package mappings below.

If attr is undefined then the default attributes are:

    AutoCommit => 1
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

=head1 Known DBD Package Mappings

The following are the known DBD driver name mappings, including ucfirst'ing
them:

    DBD::Oracle => Oracle.pm
    DBD::Sybase => Sybase.pm
    DBD::Pg => Pg.pm
    DBD::mysql => Mysql.pm
    DBD::Informix => Informix.pm

If you use this on other platforms, let me know what the mappings are.

=head2 ODBC

ODBC needed special support, so when run with DBD::ODBC, we call GetInfo
to find out what database we're connecting to, and then map to a known package.
The following are the known package mappings for ODBC:

    Microsoft SQL Server (7.0 and MSDE) => MSSQL.pm
    Microsoft SQL Server (6.5 and below) => Sybase.pm (sorry!)
    Sybase (ASE and ASA) => Sybase.pm
    Microsoft Access => Access.pm
    Informix => Informix.pm
    Oracle => Oracle.pm

Anything that isn't listed above will get mapped using the following rule:

    Get rdbms name using: $dbh->func(17, GetInfo);
    Change whitespace to a single underscore
    Add .pm on the end.

So if you need to know what your particular database will map to, simply run
the $dbh->func(17, GetInfo) method to find out.

ODBC also inserts C<$package::ODBC.pm> into the hierarchy if it exists, so
the hierarchy will look like:

    DBIx::AnyDBD <= ODBC.pm <= Informix.pm

(given that the database you're connecting to would be Informix). This is
useful because ODBC provides its own SQL abstraction layer.

=head2 ADO

ADO uses the same semantics as ODBC for determining the right driver or
module to load. However in extension to that, it inserts an ADO.pm into
the inheritance hierarchy if it exists, so the hierarchy would look like:

    DBIx::AnyDBD <= ODBC.pm <= ADO.pm <= Informix.pm

I do understand that this is not fundamentally correct, as not all ADO
connections go through ODBC, but if you're doing some of that funky stuff
with ADO (such as queries on MS Index Server) then you're not likely to
need this module!

=head1 LICENCE

This module is free software, and you may distribute it under the same 
terms as Perl itself.

=head1 SUPPORT

Commercial support for this module is available on a pay per incident
basis from Fastnet Software Ltd. Contact matt@sergeant.org for further
details. Alternatively join the DBI-Users mailing list, where I'll help
you out for free!

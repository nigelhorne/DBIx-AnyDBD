package DBIx::AnyDBD::Default;
use strict;

# Example Default class

sub prepare {
	my $self = shift;
	my $sql = shift;
	my (@params) = @_;

	# Use prepare_cached by default for a small speedup.
	
	return $self->get_dbh->prepare_cached(
			sprintf($sql, @params)
			);
}

sub do_something {
	my $self = shift;
	my ($val) = @_;
	
	# If executed on Sybase this calls ordinary prepare(),
	# on other db's it uses the above function to call prepare_cached().
	my $sth = $self->prepare(
			"SELECT SomeValue FROM SomeTable 
			WHERE SomeColumn %d",
			$val);
	
	$sth->execute;
	
	while( my $rec = $sth->fetchrow_arrayref) {
		undef $sth;
		return $rec->[0];
	}
	undef $sth;
	die "No record found!";
}

1;

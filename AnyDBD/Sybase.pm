package DBIx::AnyDBD::Sybase;
use strict;

# Example Sybase class

sub prepare {
	my $self = shift;
	my $sql = shift;
	my (@params) = @_;

	# prepare_cached doesn't work too well with Sybase transactions
	# so for Sybase we just use prepare().
	
	return $self->get_dbh->prepare(
			sprintf($sql, @params)
			);
}

1;

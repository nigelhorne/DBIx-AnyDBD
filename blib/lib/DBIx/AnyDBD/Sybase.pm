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

=head1 NAME

DBIx::AnyDBD::Sybase - example Sybase.pm

=head1 DESCRIPTION

THIS IS AN EXAMPLE - DO NOT USE IN PRODUCTION SYSTEMS

This file is meant as an example to show how DBIx::AnyDBD works.

=cut

package DBIx::AnyDBD::Sybase;
use strict;

# Example Sybase class

sub fred {
	my $self = shift;
	my @params = @_;
	warn "FRED!: $self (", join(', ', @params), ")\n";
	return;
}

1;

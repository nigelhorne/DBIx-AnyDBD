package DBIx::AnyDBD::Default;
use strict;

# Example Default class

sub goo {
	my $self = shift;
	my @params = @_;
	warn "GOO!: $self (", join(', ', @params), ")\n";
	return;
}	

1;

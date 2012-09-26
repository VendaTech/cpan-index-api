package CPAN::Index::API::Role::Clonable;

# ABSTRACT: Clones index file objects

use strict;
use warnings;

use Moose::Role;

sub clone
{
    my ($self, %params) = @_;
    $self->meta->clone_object($self, %params);
}

=pod

=head1 PROVIDES

=head2 clone

Clones the objecct. Parameters can be supplied as key/value paris to override
the values of existing attributes.

=cut

1;

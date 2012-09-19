package CPAN::Index::API::File;

# ABSTRACT: Base class for index file objects

use Moose;

sub clone
{
    my ($self, %params) = @_;
    $self->meta->clone_object($self, %params);
}

__PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

All index file implementations should inherit from this class.

=head1 PROVIDES

=head2 clone

Clones the object. See L<Class::MOP::Class/clone> for details.

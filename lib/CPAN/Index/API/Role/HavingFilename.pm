package CPAN::Index::API::Role::HavingFilename;

# ABSTRACT: Provides 'filename' attribute

use strict;
use warnings;
use Path::Class ();

use Moose::Role;

requires 'default_location';

has filename => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_filename {
    my $self = shift;
    return Path::Class::file($self->default_location)->basename;
}

1;

=pod

=head1 REQUIRES

=head2 deafult_location

Class method that returns a string specifying the path to the default location
of this file relative to the repository root.

=head1 PROVIDES

=head2 filename

Name of the current file - defaults to the basename of the path specified
in C<default_location>;

=cut

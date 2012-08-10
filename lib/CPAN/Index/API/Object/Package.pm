package CPAN::Index::API::Object::Package;

# ABSTRACT: Package entry in 02packages.details

use strict;
use warnings;

use Moose;
use namespace::clean -except => 'meta';

has name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has version => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'undef',
);

has distribution => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

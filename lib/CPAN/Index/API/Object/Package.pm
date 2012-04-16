package CPAN::Index::API::Object::Package;

use strict;
use warnings;

use Moose;
use namespace::clean -except => 'meta';

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has version => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => 'undef',
);

has distribution => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

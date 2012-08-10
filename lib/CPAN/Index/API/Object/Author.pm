package CPAN::Index::API::Object::Author;

# ABSTRACT: Author entry in 01mailrc

use strict;
use warnings;

use Moose;
use namespace::clean -except => 'meta';

has pauseid => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has email => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'CENSORED',
);

__PACKAGE__->meta->make_immutable;

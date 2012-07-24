package CPAN::Index::API::File::MailRc;

# ABSTRACT: Read and write 01mailrc.txt

our $VERSION = 0.001;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Moose;
with 'CPAN::Index::API::Role::Writer';
with 'CPAN::Index::API::Role::Reader';
use namespace::clean -except => 'meta';

has '+filename' => (
    default => '01mailrc.txt',
);

has '+subdir' => (
    default => 'authors',
);

has authors => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => { 
        author_count => 'count',
        author_list  => 'elements',
    },
);

sub sorted_authors {
    my $self = shift;
    return sort { $a->pauseid cmp $b->pauseid } $self->author_list;
}

sub parse {
    my ( $self, $content ) = @_;
    
    my @authors;

    if ($content)
    {

        foreach my $line ( split "\n", $content ) {
            my ( $alias, $pauseid, $long ) = split ' ', $line, 3;
            $long =~ s/^"//;
            $long =~ s/"$//;
            my ($name, $email) = $long =~ /(.*) <(.+)>$/;
            my $author = CPAN::Index::API::Object::Author->new(
                pauseid => $pauseid,
                name    => $name,
                email   => $email,
            );

            push @authors, $author;
        }
    }

    return ( authors => \@authors );
}

sub default_locations
{
    return ['authors', '01mailrc.txt.gz'];
}

__PACKAGE__->meta->make_immutable;

__DATA__
[% 
    foreach my $author ($self->sorted_authors) {
        $OUT .= sprintf qq[alias %s "%s <%s>"\n],
            $author->pauseid,
            $author->name,
            $author->email;
    }
%]

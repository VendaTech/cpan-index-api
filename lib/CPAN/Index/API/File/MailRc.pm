package CPAN::Index::API::File::MailRc;

# ABSTRACT: Read and write 01mailrc.txt

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

=pod

=head1 SYNOPSIS

  my $mailrc = CPAN::Index::File::MailRc->parse_from_repo_uri(
    'http://cpan.perl.org'
  );

  foreach my $author ($mailrc->sorted_authors) {
    ... # do something
  }

=head1 DESCRIPTION

This is a class to read and write 01mailrc.txt

=head1 METHODS

=head2 authors

List of authors.

=head2 sorted_authors

List of authors sorted by pause id.

=head2 parse

Parses the file and reurns its representation as a data structure.

=head1 METHODS FROM ROLES

=over

=item <CPAN::Index::API::Role::Reader/read_from_string>

=item <CPAN::Index::API::Role::Reader/read_from_file>

=item <CPAN::Index::API::Role::Reader/read_from_tarball>

=item <CPAN::Index::API::Role::Reader/read_from_repo_path>

=item <CPAN::Index::API::Role::Reader/read_from_repo_uri>

=item L<CPAN::Index::API::Role::Writer/filename>

=item L<CPAN::Index::API::Role::Writer/tarball_suffix>

=item L<CPAN::Index::API::Role::Writer/repo_path>

=item L<CPAN::Index::API::Role::Writer/template>

=item L<CPAN::Index::API::File::Role::Writer/content>

=item L<CPAN::Index::API::File::Role::Writer/ write_to_file>

=item L<CPAN::Index::API::File::Role::Writer/write_to_tarball>

=back

=cut

__DATA__
[%
    foreach my $author ($self->sorted_authors) {
        $OUT .= sprintf qq[alias %s "%s <%s>"\n],
            $author->pauseid,
            $author->name,
            $author->email;
    }
%]

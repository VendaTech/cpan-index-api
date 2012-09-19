package CPAN::Index::API::File::MailRc;

# ABSTRACT: Read and write 01mailrc.txt

use strict;
use warnings;
use Scalar::Util qw(blessed);
use namespace::autoclean;
use Moose;

extends qw(CPAN::Index::API::File);
with qw(CPAN::Index::API::Role::Writer CPAN::Index::API::Role::Reader);

has authors => (
    is      => 'bare',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        author_count => 'count',
        authors      => 'elements',
    },
);

sub sorted_authors {
    my $self = shift;
    return sort { $a->{authorid} cmp $b->{authorid} } $self->authors;
}

sub parse {
    my ( $self, $content ) = @_;

    my @authors;

    if ($content)
    {

        foreach my $line ( split "\n", $content ) {
            my ( $alias, $authorid, $long ) = split ' ', $line, 3;
            $long =~ s/^"//;
            $long =~ s/"$//;
            my ($name, $email) = $long =~ /(.*) <(.+)>$/;
            my $author = {
                authorid => $authorid,
                name     => $name,
                email    => $email,
            };

            push @authors, $author;
        }
    }

    return ( authors => \@authors );
}

sub default_location { 'authors/01mailrc.txt.gz' }

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

List of hashres containing author data. The structure of the hashrefs is
as follows:

=over

=item authorid

CPAN id of the author. This should be a string containing only capital latin
letters and is at least 2 characters long.

=item name

Author's full name.

=item email

Author's email. The string C<CENSORED> may appear where the email address is
not available or onot to be displayed publicly.

=back

=head2 sorted_authors

List of authors sorted by pause id.

=head2 parse

Parses the file and reurns its representation as a data structure.

=head2 default_location

Default file location - C<authors/01mailrc.txt.gz>.

=head1 METHODS FROM ROLES

=over

=item <CPAN::Index::API::Role::Reader/read_from_string>

=item <CPAN::Index::API::Role::Reader/read_from_file>

=item <CPAN::Index::API::Role::Reader/read_from_tarball>

=item <CPAN::Index::API::Role::Reader/read_from_repo_path>

=item <CPAN::Index::API::Role::Reader/read_from_repo_uri>

=item L<CPAN::Index::API::Role::Writer/tarball_is_default>

=item L<CPAN::Index::API::Role::Writer/repo_path>

=item L<CPAN::Index::API::Role::Writer/template>

=item L<CPAN::Index::API::File::Role::Writer/content>

=item L<CPAN::Index::API::File::Role::Writer/write_to_file>

=item L<CPAN::Index::API::File::Role::Writer/write_to_tarball>

=back

=cut

__DATA__
[%
    foreach my $author ($self->sorted_authors) {
        $OUT .= sprintf qq[alias %s "%s <%s>"\n],
            $author->{authorid},
            $author->{name},
            $author->{email} ? $author->{email} : 'CENSORED';
    }
%]

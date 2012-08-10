use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use File::Slurp qw(read_file);
use CPAN::Index::API::File::MailRc;
use CPAN::Index::API::Object::Author;

my $mailrc = <<'EndOfMailRc';
alias FOOBAR "Foo Bar <foo@bar.com>"
alias LOCAL "Local <CENSORED>"
alias PSHANGOV "Peter Shangov <pshangov@example.com>"
EndOfMailRc

my @authors = map {
    CPAN::Index::API::Object::Author->new(
        pauseid => $_->{pauseid},
        name    => $_->{name},
        $_->{email} ? ( email => $_->{email} ) : (),
    );
} (
    { pauseid => 'FOOBAR',   name => 'Foo Bar',       email => 'foo@bar.com' },
    { pauseid => 'PSHANGOV', name => 'Peter Shangov', email => 'pshangov@example.com' },
    { pauseid => 'LOCAL',    name => 'Local' },
);

my $writer = CPAN::Index::API::File::MailRc->new(
    authors => \@authors,
);

eq_or_diff( $writer->content, $mailrc, 'mailrc' );

my ($fh, $filename) = tempfile;
$writer->write_to_file($filename);
my $content = read_file($filename);
eq_or_diff( $content, $mailrc, 'write to file' );

my $reader = CPAN::Index::API::File::MailRc->read_from_string($mailrc);

my %expected = (
    filename       => '01mailrc.txt',
    tarball_suffix => 'gz',
    subdir         => 'authors'
);

foreach my $attribute ( keys %expected ) {
    is ( $reader->$attribute, $expected{$attribute}, "read $attribute" );
}

my @three_authors = $reader->author_list;

is ( scalar @three_authors, 3, "reader has 3 authors" );

(my $foobar) = grep { $_->pauseid eq 'FOOBAR' } @three_authors;

isa_ok ($foobar, 'CPAN::Index::API::Object::Author' );

is ( $foobar->pauseid, 'FOOBAR',      'read author pauseid' );
is ( $foobar->name,    'Foo Bar',     'read author name'    );
is ( $foobar->email,   'foo@bar.com', 'read author email'   );

done_testing;

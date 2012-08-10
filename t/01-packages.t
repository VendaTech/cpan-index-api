use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use File::Slurp qw(read_file);
use Compress::Zlib qw(gzopen);
use CPAN::Index::API::File::PackagesDetails;
use CPAN::Index::API::Object::Package;

# defaults
my $with_packages = <<'EndOfPackages';
File:         02packages.details.txt
URL:          http://www.example.com/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Index::API::File::PackagesDetails 0.001
Line-Count:   4
Last-Updated: Fri Mar 23 18:23:15 2012 GMT

Acme::Qux                           9.99  P/PS/PSHANGOV/Acme-Qux-9.99.tar.gz
Baz                                1.234  L/LO/LOCAL/Baz-1.234.tar.gz
Foo                                 0.01  F/FO/FOOBAR/Foo-0.01.tar.gz
Foo::Bar                           undef  F/FO/FOOBAR/Foo-0.01.tar.gz
EndOfPackages

my $without_packages = <<'EndOfPackages';
File:         02packages.details.txt
URL:          http://www.example.com/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Index::API::File::PackagesDetails 0.001
Line-Count:   0
Last-Updated: Fri Mar 23 18:23:15 2012 GMT
EndOfPackages

my @packages = map {
    CPAN::Index::API::Object::Package->new(
        name         => $_->{name},
        version      => $_->{version},
        distribution => $_->{distribution},
    );
} (
    { name => 'Foo',       version => '0.01',  distribution => 'F/FO/FOOBAR/Foo-0.01.tar.gz' },
    { name => 'Foo::Bar',  version =>  undef,  distribution => 'F/FO/FOOBAR/Foo-0.01.tar.gz' },
    { name => 'Baz',       version => '1.234', distribution => 'L/LO/LOCAL/Baz-1.234.tar.gz' },
    { name => 'Acme::Qux', version => '9.99',  distribution => 'P/PS/PSHANGOV/Acme-Qux-9.99.tar.gz' },
);

my $writer_with_packages = CPAN::Index::API::File::PackagesDetails->new(
    repo_uri     => 'http://www.example.com',
    last_updated => 'Fri Mar 23 18:23:15 2012 GMT',
    written_by   => 'CPAN::Index::API::File::PackagesDetails 0.001',
    packages     => \@packages,
);

my $writer_without_packages = CPAN::Index::API::File::PackagesDetails->new(
    repo_uri     => 'http://www.example.com',
    last_updated => 'Fri Mar 23 18:23:15 2012 GMT',
    written_by   => 'CPAN::Index::API::File::PackagesDetails 0.001',
);

eq_or_diff( $writer_with_packages->content, $with_packages, 'with packages' );
eq_or_diff( $writer_without_packages->content, $without_packages, 'without packages' );

my ($fh_with_packages, $filename_with_packages) = tempfile;
$writer_with_packages->write_to_file($filename_with_packages);
my $content_with_packages = read_file($filename_with_packages);
eq_or_diff( $content_with_packages, $with_packages, 'write to file with packages' );

my ($fh_without_packages, $filename_without_packages) = tempfile;
$writer_without_packages->write_to_file($filename_without_packages);
my $content_without_packages = read_file($filename_without_packages);
eq_or_diff( $content_without_packages, $without_packages, 'write to file without packages' );

my $reader_with_packages = CPAN::Index::API::File::PackagesDetails->read_from_string($with_packages);
my $reader_without_packages = CPAN::Index::API::File::PackagesDetails->read_from_string($without_packages);

my %expected = (
    last_updated   => 'Fri Mar 23 18:23:15 2012 GMT',
    intended_for   => 'Automated fetch routines, namespace documentation.',
    tarball_suffix => 'gz',
    description    => 'Package names found in directory $CPAN/authors/id/',
    uri            => 'http://www.example.com/modules/02packages.details.txt',
    subdir         => 'modules',
    filename       => '02packages.details.txt',
    written_by     => 'CPAN::Index::API::File::PackagesDetails 0.001',
    columns        => 'package name, version, path',
);

foreach my $attribute ( keys %expected ) {
    is ( $reader_without_packages->$attribute, $expected{$attribute}, "read $attribute (without packages)" );
}

my @no_packages = $reader_without_packages->package_list;

ok ( !@no_packages, "reader without packages has no packages" );

foreach my $attribute ( keys %expected ) {
    is ( $reader_with_packages->$attribute, $expected{$attribute}, "read $attribute (with packages)" );
}

my @four_packages = $reader_with_packages->package_list;

is ( scalar @four_packages, 4, "reader with packages has 4 packages" );

(my $foo) = grep { $_->name eq 'Foo' } @four_packages;

isa_ok ($foo, 'CPAN::Index::API::Object::Package' );

is ( $foo->name,         'Foo',                         'read package name'         );
is ( $foo->version,      '0.01',                        'read package version'      );
is ( $foo->distribution, 'F/FO/FOOBAR/Foo-0.01.tar.gz', 'read package distribution' );

my ($tarball_fh_with_packages, $tarball_name_with_packages) = tempfile;
$writer_with_packages->write_to_tarball($tarball_name_with_packages);

my ($buffer, $content_from_tarball);
my $gz = gzopen($tarball_name_with_packages, 'rb');
$content_from_tarball .= $buffer while $gz->gzread($buffer) > 0 ;
$gz->gzclose;

is ( $content_from_tarball, $with_packages, 'read_from_tarball');

done_testing;

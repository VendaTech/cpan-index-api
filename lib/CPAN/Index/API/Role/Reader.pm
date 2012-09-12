package CPAN::Index::API::Role::Reader;

# ABSTRACT: Role for reading index files

use strict;
use warnings;
use File::Slurp    qw(read_file);
use File::Temp     qw(tempfile);
use Scalar::Util   qw(blessed);
use Path::Class    qw(file);
use Carp           qw(croak);
use Compress::Zlib qw(gzopen Z_STREAM_END), '$gzerrno';
use Moose::Role;
use namespace::clean -except => 'meta';

requires 'parse';
requires 'default_locations';

sub read_from_string
{
    my ($self, $content, %args) = @_;

    %args = ( $self->parse($content), %args );

    if ( blessed $self )
    {
        foreach my $key ( keys %args )
        {
            $self->$key($args{$key});
        }
    }
    else
    {
        return $self->new(%args);
    }
}

sub read_from_file {
    my ($self, $file, %args) = @_;
    my $content = read_file($file);
    return $self->read_from_string($content, %args);
}

sub read_from_tarball
{
    my ($self, $tarball, %args) = @_;

    my $gz = gzopen($tarball, 'rb') or croak "Cannot open $tarball: $gzerrno";

    my ($buffer, $content);

    $content .= $buffer while $gz->gzread($buffer) > 0 ;

    croak "Error reading from $tarball: $gzerrno" . ($gzerrno+0) . "\n"
        if $gzerrno != Z_STREAM_END;

    $gz->gzclose and croak "Error closing $tarball";

    return $self->read_from_string($content, %args);
}

sub read_from_repo_path
{
    my ($self, $repo_path, %args) = @_;

    $args{repo_path} = $repo_path;

    my @default_locations = $self->default_locations;

    my $path_to_file = file(
        $repo_path, @{ $default_locations[0] }
    )->stringify;

    return $self->read_from_tarball(
        $path_to_file, %args
    );
}

sub read_from_repo_uri
{
    my ($self, $repo_uri, %args) = @_;

    $args{repo_uri} = $repo_uri;

    my $uri = URI->new( $repo_uri );
    my @default_locations = $self->default_locations;

    $uri->path_segments( $uri->path_segments, @{ $default_locations[0] } );

    my $uri_as_string = $uri->as_string;

    my $content = LWP::Simple::get( $uri_as_string )
        or croak "Failed to fetch $uri_as_string";

    my ( $fh, $filename ) = tempfile;
    print $fh LWP::Simple::get( $uri->as_string ) or croak $!;
    close $fh or croak $!;

    return $self->read_from_tarball( $filename, %args );
}

1;

=head1 DESCRIPTION

This role provides a collection of utility constructors for CPAN index file
objects.

=head1 REQUIRES

=head2 parse

This class method (generally invoked as part of the construction phase)
should accept a string containing an index file, and return a list of
key/value pairs suitable for passing to the constructor of the consuming class.

=head1 PROVIDES

=head2 read_from_string

Construct a new index file object by reading the file contents from a string.

=head2 read_from_file

Construct a new index file object by reading the file contents from a filename.

=head2 read_from_tarball

Construct a new index file object by reading the file contents from a tarball.

=head2 read_from_repo_path

Construct a new index file object by locating and parsing a file in a local
repository.

=head2 read_from_repo_uri

Construct a new index file object by locating and parsing a file in a remote
repository.

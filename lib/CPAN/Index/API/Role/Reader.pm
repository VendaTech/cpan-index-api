package CPAN::Index::API::Role::Reader;

use strict;
use warnings;
use File::Slurp    qw(read_file);
use Scalar::Util   qw(blessed);
use Path::Class    qw(file);
use Carp           qw(croak);
use Compress::Zlib qw(gzopen Z_STREAM_END), '$gzerrno';
use Moose::Role;
use namespace::clean -except => 'meta';

requires 'parse';

sub read_from_string {
    my ($self, $content) = @_;
    my %args = $self->parse($content);

    if ( blessed $self ) {
        foreach my $key ( keys %args ) {
            $self->$key($args{$key});
        }
    } else {
        return $self->new(%args);
    }
}

sub read_from_file {
    my ($self, $file) = @_;
    my $content = read_file($file);
    return $self->read_from_string($content);
}

sub read_from_tarball {
    my ($self, $tarball) = @_;

    my $gz = gzopen($tarball, 'rb') or croak "Cannot open $tarball: $gzerrno";
    
    my ($buffer, $content);

    $content .= $buffer while $gz->gzread($buffer) > 0 ;
 
    croak "Error reading from $tarball: $gzerrno" . ($gzerrno+0) . "\n"
        if $gzerrno != Z_STREAM_END ;
     
    $gz->gzclose and croak "Error closing $tarball";

    return $self->read_from_string($content);
}

sub new_from_path
{
    my ($class, %args) = @_;

    my $repo_path = $args{repo_path};

    my $path_to_packages_details = file(
        $repo_path, 'modules', '02packages.details.txt.gz'
    )->stringify;

    my $packages_details = $class->read_from_tarball(
        $path_to_packages_details
    );
    
    #FIXME
    $packages_details->$_($args{$_}) for keys %args;

    return $packages_details;
}

1;

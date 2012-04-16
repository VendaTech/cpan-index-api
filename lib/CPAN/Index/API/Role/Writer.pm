package CPAN::Index::API::Role::Writer;

# ABSTRACT: Role for writing index files

use strict;
use warnings;

use File::Slurp    qw(write_file read_file);
use File::Path     qw(make_path);
use File::Basename qw(fileparse);
use Path::Class    qw(file dir);
use Text::Template qw(fill_in_string);
use Symbol         qw(qualify_to_ref);
use Scalar::Util   qw(blessed);
use Carp           qw(croak);
use Compress::Zlib qw(gzopen $gzerrno);
use Moose::Role;
use namespace::clean -except => 'meta';

has filename => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has tarball_suffix => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'gz',
);

has subdir => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has repo_path => (
    is  => 'rw',
    isa => 'Str',
);

has template => (
    is         => 'rw',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

has content => (
    is         => 'rw',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_template {
    my $self = shift;
    my $glob = qualify_to_ref("DATA", blessed $self);
    return read_file($glob);
}

sub _build_content {
    my $self = shift;
    my $content = fill_in_string(
        $self->template,
        DELIMITERS => [ '[%', '%]' ],
        HASH       => { self  => \$self },
    );
    chomp $content;
    return $content;
}

sub write_to_tarball {
    my ( $self, $filename ) = @_;
    my $file = $self->_prepare_file($filename, $self->tarball_suffix);
    my $gz = gzopen($file->stringify, 'wb') or croak "Cannot open $file: $gzerrno";
    $gz->gzwrite($self->content);
    $gz->gzclose and croak "Error closing $file";
}

sub write_to_file {
    my ( $self, $filename ) = @_;
    my $file = $self->_prepare_file($filename);
    write_file($file, { err_mode => 'carp' }, $self->content);
}

sub _prepare_file {
    my ( $self, $file, $suffix ) = @_;

    if ( defined $file ) {
        $file = file($file);
    } elsif ( not defined $file and $self->repo_path ) {
        my $filename = $self->filename;

        if ($suffix) {
             my ($basename) = fileparse($filename);
             $filename = "$basename.$suffix";
        }

        $file = file( $self->repo_path, $self->subdir, $filename);
    } else {
        die "Unable to write to file without a filename or repo path";
    }

    $file->dir->mkpath unless -e $file->dir;

    return $file;
}

1;

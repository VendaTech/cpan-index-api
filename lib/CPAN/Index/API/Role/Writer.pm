package CPAN::Index::API::Role::Writer;

# ABSTRACT: Role for writing index files

use strict;
use warnings;

use File::Slurp    qw(write_file read_file);
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
        croak "Unable to write to file without a filename or repo path";
    }

    $file->dir->mkpath unless -e $file->dir;

    return $file;
}

1;

=pod

=head1 DESCRIPTION

This role provides attributes and methods shared between classes that write
index files.

=head1 REQUIRES

This role does not explicitly require any methods, but it expects that
consuming packages will have a C<DATA> section that contains the template
to use for generating the file contents.

=head1 PROVIDES

=head2 filename

Required attribute. Base name of index file, e.g. C<02packages.details.txt>.

=head2 subdir

Required attribute. Directory where the index file is located, relative to
the repo root.

=head2 tarball_suffix

Optional attribute. Suffix to use for the compressed version of the index file.
Default is C<gz>.

=head2 repo_path

Optional attribute. Path to the repository root.

=head2 template

Optional attribute. The template to use for generating the index files. The
defalt is fetched from the C<DATA> section of the consuming package.

=head2 content

Optional attribute. The index file content. Built by default from the
provided L</template>.

=head2 write_to_file

This method builds the file content if necessary and writes it to a file. The
full file path is calculated from L</subdir> and L</filename>.

=head2 write_to_tarball

This method builds the file content if necessary and writes it to a tarball.
The full tarball file path is calculated from L</subdir>, L</filename> and
L<tarball_suffix>.

=cut

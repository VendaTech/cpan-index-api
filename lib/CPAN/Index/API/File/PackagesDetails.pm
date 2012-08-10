package CPAN::Index::API::File::PackagesDetails;

# ABSTRACT: Write 02packages.details

use strict;
use warnings;
use URI;
use URI::file;
use Path::Class qw(file dir);
use Carp        qw(croak);
use List::Util  qw(first);
use Moose;
with 'CPAN::Index::API::Role::Reader';
with 'CPAN::Index::API::Role::Writer';
use namespace::clean -except => 'meta';

has '+filename' => (
    default  => '02packages.details.txt',
);

has '+subdir' => (
    default  => 'modules',
);

has uri => (
    is         => 'rw',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

has repo_uri => (
    is  => 'rw',
    isa => 'Str',
);

has description => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'Package names found in directory $CPAN/authors/id/',
);

has columns => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'package name, version, path',
);

has intended_for => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'Automated fetch routines, namespace documentation.',
);

has written_by => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => "CPAN::Index::API::File::PackagesDetails $CPAN::Index::API::File::PackagesDetails::VERSION",
);

has last_updated => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub { scalar gmtime() . " GMT" },
);

has packages => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        package_count => 'count',
        package_list  => 'elements',
        add_package   => 'push',
    },
);

sub BUILDARGS {
    my ( $class, %args ) = @_;

    if ( $args{uri} or $args{repo_uri} )
    {
        return \%args;
    }
    elsif ($args{repo_path})
    {
        $args{repo_uri} = URI::file->new(
            dir($args{repo_path})->absolute,
        )->as_string;

        return \%args;
    }
    else
    {
        croak "Either 'uri', 'repo_uri' or 'repo_path' is required";
    }
}

sub _build_uri {
    my $self = shift;
    my $uri = URI->new($self->repo_uri);
    $uri->path_segments(
        grep { $_ ne '' } $uri->path_segments,
        $self->subdir,
        $self->filename,
    );
    return $uri->as_string;
}

sub package
{
    my ($self, $name) = @_;
    return first { $_->name eq $name } $self->package_list;
}

sub sorted_packages
{
    my $self = shift;
    return sort { $a->name cmp $b->name } $self->package_list;
}

sub parse {
    my ( $self, $content ) = @_;

    my %map = (
        'File'         => 'file',
        'URL'          => 'uri',
        'Description'  => 'description',
        'Columns'      => 'columns',
        'Intended-For' => 'intended_for',
        'Written-By'   => 'written_by',
        'Line-Count'   => 'line_count',
        'Last-Updated' => 'last_updated',
    );

    my @lines = split "\n", $content;
    my ( %args, @packages );

    while ( my $line = shift @lines ) {
        last if $line =~ /^\s*$/;
        next unless my ( $key, $value ) = $line =~ /^([^:]+):\s*(.*)/;
        $args{$map{$key}} = $value;
    }

    foreach my $line ( @lines ) {
        my ( $name, $version, $distribution ) = split ' ', $line;
        my $package = CPAN::Index::API::Object::Package->new(
            name         => $name,
            version      => $version,
            distribution => $distribution,
        );
        push @packages, $package;
    }

    $args{packages} = \@packages if @packages;

    return %args;
}

sub default_locations
{
    return ['modules', '02packages.details.txt.gz'];
}

__PACKAGE__->meta->make_immutable;

__DATA__
File:         [% $self->filename      %]
URL:          [% $self->uri           %]
Description:  [% $self->description   %]
Columns:      [% $self->columns       %]
Intended-For: [% $self->intended_for  %]
Written-By:   [% $self->written_by    %]
Line-Count:   [% $self->package_count %]
Last-Updated: [% $self->last_updated  %]
[%
    if ($self->package_count)
    {
        $OUT .= "\n";
        foreach my $package ($self->sorted_packages) {
            $OUT .= sprintf "%-34s %5s  %s\n",
                $package->name,
                defined $package->version ? $package->version : 'undef',
                $package->distribution;
        }
    }
    else
    {
        $OUT .= ''; # keeps Text::Template happy
    }
%]

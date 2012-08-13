package CPAN::Index::API;

# ABSTRACT: OO interface to the CPAN index files

use strict;
use warnings;

use Path::Class qw(dir);
use Carp        qw(croak);
use Class::Load qw(load_class);
use Moose;
use Moose::Util::TypeConstraints qw(find_type_constraint);
use namespace::clean -except => 'meta';

has files => (
    is      => 'ro',
    isa     => 'HashRef[Object]',
    traits  => ['Hash'],
    handles => { all_files => 'values', file => 'get' },
);

has repo_path =>
(
    is       => 'ro',
    isa      => 'Str',
);

has repo_uri =>
(
    is       => 'ro',
    isa      => 'Str',
);

sub BUILDARGS {
    my ( $class, %args ) = @_;

    croak "Please specifiy which files to load" unless $args{files};

    my $constraint = find_type_constraint('ArrayRef[Str]');

    if ( $constraint->check($args{files}) )
    {
        my %files;

        foreach my $file ( @{ $args{files} } )
        {
            my $package_name = "CPAN::Index::API::File::$file";
            load_class $package_name;
            $files{$file} = $package_name->new(
                repo_path => $args{repo_path},
                repo_uri  => $args{repo_uri},
            );
        }

        $args{files} = \%files;
    }

    if ( $args{repo_path} and not $args{repo_uri} )
    {
        $args{repo_uri} = URI::file->new(
            dir($args{repo_path})->absolute
        )->as_string;
    }

    return \%args;
}

sub new_from_repo_path
{
    my ($class, %args) = @_;

    if ( $args{repo_path} and not $args{repo_uri} )
    {
        $args{repo_uri} = URI::file->new(
            dir($args{repo_path})->absolute
        )->as_string;
    }

    my $files = delete $args{files};
    my %files;

    croak "Please specifiy which files to load" unless $files;

    foreach my $file ( @$files )
    {
        my $package_name = "CPAN::Index::API::File::$file";
        load_class $package_name;

        $files{$file} = $package_name->read_from_repo_path(
            $args{repo_path}
        );
    }

    return $class->new( %args, files => \%files );
}

sub new_from_repo_uri
{
    my ($class, %args) = @_;

    my $files = delete $args{files};
    my %files;

    croak "Please specifiy which files to load" unless $files;

    foreach my $file ( @$files )
    {
        my $package_name = "CPAN::Index::API::File::$file";
        load_class $package_name;

        $files{$file} = $package_name->read_from_repo_uri(
            $args{repo_uri}
        );
    }

    return $class->new( %args, files => \%files );
}

sub write_all_files
{
    my $self = shift;

    dir($self->repo_path, $_)->mkpath for qw(authors modules);
    $_->write_to_tarball for $self->all_files;
}

__PACKAGE__->meta->make_immutable;

package CPAN::Index::API;

use strict;
use warnings;

use File::Path  qw(make_path);
use Path::Class qw(file dir);
use List::Util  qw(first);

use CPAN::Index::API::File::PackagesDetails;
use CPAN::Index::API::File::ModList;
use CPAN::Index::API::File::MailRc;

use Moose;
use namespace::clean -except => 'meta';

has repo_path => 
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has repo_uri => 
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has packages_details => 
(
    is         => 'ro',
    isa        => 'CPAN::Index::API::File::PackagesDetails',
    lazy_build => 1,
    handles    => ['packages', 'add_package', 'package_list' ],
);

has mod_list => 
(
    is         => 'ro',
    isa        => 'CPAN::Index::API::File::ModList',
    lazy_build => 1,
    handles    => ['modules'],
);

has mail_rc => 
(
    is         => 'ro',
    isa        => 'CPAN::Index::API::File::MailRc',
    lazy_build => 1,
    handles    => ['authors'],
);

sub _build_packages_details
{
    my $self = shift;

    return CPAN::Index::API::File::PackagesDetails->new(
        repo_path => $self->repo_path,
        repo_uri  => $self->repo_uri,
    );
}

sub _build_mod_list
{
    my $self = shift;

    return CPAN::Index::API::File::ModList->new(
        repo_path => $self->repo_path,
    );
}

sub _build_mail_rc
{
    my $self = shift;

    return CPAN::Index::API::File::MailRc->new(
        repo_path => $self->repo_path,
    );
}

sub write_all_files
{
    my $self = shift;

    make_path( dir($self->repo_path, 'authors')->stringify );
    make_path( dir($self->repo_path, 'modules')->stringify );

    $self->packages_details->write_to_tarball;
    $self->mod_list->write_to_tarball;
    $self->mail_rc->write_to_file;
}

sub find_package_by_name
{
    my ($self, $name) = @_;

    my $packages = $self->packages;
    return unless $packages;

    return first { $_->name eq $name } @$packages;
}

sub new_from_path
{
    my ($class, %args) = @_;

    my $packages_details = 
        CPAN::Index::API::File::PackagesDetails->new_from_path(
            %args
        );

    return $class->new( packages_details => $packages_details, %args );
}

sub new_from_uri
{
    my ($class, %args) = @_;

    my $packages_details = 
        CPAN::Index::API::File::PackagesDetails->read_from_repo_uri(
            $args{repo_uri}
        );

    return $class->new( packages_details => $packages_details, %args );
}

__PACKAGE__->meta->make_immutable;

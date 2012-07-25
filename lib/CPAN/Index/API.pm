package CPAN::Index::API;

use strict;
use warnings;

use File::Path  qw(make_path);
use Path::Class qw(file dir);
use Carp        qw(croak);
use CPAN::Index::API::File::PackagesDetails;
use CPAN::Index::API::File::ModList;
use CPAN::Index::API::File::MailRc;

use Moose;
use namespace::clean -except => 'meta';

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

has packages_details => 
(
    is         => 'ro',
    isa        => 'CPAN::Index::API::File::PackagesDetails',
    lazy_build => 1,
    handles    => ['packages', 'add_package', 'package_list', 'package' ],
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

sub BUILDARGS {
    my ( $class, %args ) = @_;

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
    my ($self, $repo_path) = @_;

    my %args = ( repo_path => $repo_path );

    $args{packages_details} = 
        CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_path);

    $args{mail_rc} = 
        CPAN::Index::API::File::MailRc->read_from_repo_path($repo_path);

    $args{mod_list} = 
        CPAN::Index::API::File::ModList->read_from_repo_path($repo_path);

    return $self->new(%args);
}

sub new_from_repo_uri
{
    my ($self, $repo_uri) = @_;

    my %args;

    $args{packages_details} = 
        CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_uri);

    $args{mail_rc} = 
        CPAN::Index::API::File::MailRc->read_from_repo_path($repo_uri);

    $args{mod_list} = 
        CPAN::Index::API::File::ModList->read_from_repo_path($repo_uri);

    return $self->new(%args);
}
sub write_all_files
{
    my $self = shift;

    make_path( dir($self->repo_path, 'authors')->stringify );
    make_path( dir($self->repo_path, 'modules')->stringify );

    $self->packages_details->write_to_tarball;
    $self->mod_list->write_to_tarball;
    $self->mail_rc->write_to_tarball;
}

__PACKAGE__->meta->make_immutable;

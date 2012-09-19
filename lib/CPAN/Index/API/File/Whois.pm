package CPAN::Index::API::File::Whois;

# ABSTRACT: Interface to 00whois.xml

use strict;
use warnings;

use XML::Twig;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;

extends qw(CPAN::Index::API::File);
with qw(CPAN::Index::API::Role::Reader CPAN::Index::API::Role::Writer);

class_has _field_map => (
    is      => 'bare',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => { 
        _original_fields     => 'keys',
        _name_for_orig_field => 'get',
    },
    default => sub { {
        asciiname   => 'ascii_name',
        fullname    => 'full_name',
        email       => 'email',
        has_cpandir => 'has_cpandir',
        homepage    => 'homepage',
        id          => 'cpanid',
        info        => 'info',
        type        => 'type',
    } },
);

has last_generated => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { scalar gmtime() . " GMT" },
);

has generated_by => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Id',
);

has authors => (
    is      => 'bare',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        authors    => 'elements',
        add_author => 'push',
    },
);

sub author
{
    my ($self, $name) = @_;
    return first { $_->{cpanid} eq $name } $self->authors;
}

sub parse {
    my ( $self, $content ) = @_;

    my $twig = XML::Twig->new;
    my $xml  = $twig->parse($content);
    my $root = $xml->root;

    my @authors;

    foreach my $author ( $xml->root->children('cpanid') ) {
        my %data;

        foreach my $field ( $self->_original_fields ) {
            my $elt = $author->first_child($field);
            $data{ $self->_name_for_orig_field($field) } = $elt->text if $elt;
        }

        push @authors, \%data;
    }

   return (
        last_generated => $root->att('last-generated'),
        generated_by   => $root->att('generated-by'),
        authors        => \@authors,
    );
}

sub _build_content {
    my $self = shift;

    my $twig = XML::Twig->new( pretty_print => 'indented' );
    $twig->parse(q[<?xml version="1.0" encoding="UTF-8"?><cpan-whois xmlns='http://www.cpan.org/xmlns/whois' />]);
    $twig->root->set_att(
        'last-generated' => $self->last_generated,
        'generated-by'   => $self->generated_by,
    );

    foreach my $author ($self->authors) {
        my $elt_cpanid = XML::Twig::Elt->new('cpanid');
        
        foreach my $name ( $self->_original_fields ) {
            if ( exists $author->{ $self->_name_for_orig_field($name) } ) {
                my $elt_attribute = XML::Twig::Elt->new($name);
                $elt_attribute->set_text(
                    $author->{ $self->_name_for_orig_field($name) }
                );
                $elt_attribute->paste( last_child => $elt_cpanid );
            }
        }

        $elt_cpanid->paste( last_child => $twig->root );
    }

    return $twig->sprint;
}

sub default_location { 'authors/00whois.xml' }

__PACKAGE__->meta->make_immutable;

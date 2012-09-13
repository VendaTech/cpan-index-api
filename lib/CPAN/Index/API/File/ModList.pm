package CPAN::Index::API::File::ModList;

# ABSTRACT: Read and write 03modlist.data

use strict;
use warnings;
use URI;
use Carp qw(carp croak);
use Moose;
with 'CPAN::Index::API::Role::Reader';
with 'CPAN::Index::API::Role::Writer';
use namespace::clean -except => 'meta';

has '+filename' => (
    default  => '03modlist.data',
);

has '+subdir' => (
    default  => 'modules',
);

has description => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'Package names found in directory $CPAN/authors/id/',
);

has written_by => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => "CPAN::Index::API::File::ModList $CPAN::Index::API::File::ModList::VERSION",
);

has date => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub { scalar gmtime() . " GMT" },
);

has modules => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        module_count => 'count',
        module_list  => 'elements',
    },
);

# code from Parse::CPAN::Modlist
sub parse {
    my ( $self, $content ) = @_;

    ### get rid of the comments and the code ###
    ### need a smarter parser, some people have this in their dslip info:
    # [
    # 'Statistics::LTU',
    # 'R',
    # 'd',
    # 'p',
    # 'O',
    # '?',
    # 'Implements Linear Threshold Units',
    # ...skipping...
    # "\x{c4}dd \x{fc}ml\x{e4}\x{fc}ts t\x{f6} \x{eb}v\x{eb}r\x{ff}th\x{ef}ng!",
    # 'BENNIE',
    # '11'
    # ],
    ### also, older versions say:
    ### $cols = [....]
    ### and newer versions say:
    ### $CPANPLUS::Modulelist::cols = [...]
    $content =~ s/.+}\s+(\$(?:CPAN::Modulelist::)?cols)/$1/s;

    ### split '$cols' and '$data' into 2 variables ###
    my ($ds_one, $ds_two) = split ';', $content, 2;

    ### eval them into existance ###
    my ($columns, $data, @modules, %args );

    $columns = eval $ds_one;
    croak "Error in eval of 03modlist.data source files: $@" if $@;

    $data = eval $ds_two;
    croak "Error in eval of 03modlist.data source files: $@" if $@;

    my %map = (
        modid       => 'name',
        statd       => 'development_stage',
        stats       => 'support_level',
        statl       => 'language_used',
        stati       => 'interface_style',
        statp       => 'public_license',
        userid      => 'author',
        chapterid   => 'chapterid',
        description => 'description',
    );

    if ( my @unknown_columns = grep { ! $map{$_} } @$columns ) {
        carp "Found unknown columns in 03modlist.data: " 
             . join ', ', @unknown_columns;
    }

    foreach my $entry ( @$data ) {
        my %module;

        @module{@map{@$columns}} = @$entry;
        $module{chapterid} = int($module{chapterid});
        
        $module{dslip} = join '', @module{qw(
            development_stage
            support_level
            language_used
            interface_style
            public_license
        )};

        push @modules, \%module;
    }

    $args{modules} = \@modules if @modules;

    return %args;
}

sub default_locations
{
    return ['modules', '03modlist.data.gz'];
}

__PACKAGE__->meta->make_immutable;

=pod

=head1 SYNOPSIS

  my $modlist = CPAN::Index::File::ModList->parse_from_repo_uri(
    'http://cpan.perl.org'
  );

  foreach my $module ($modlist->module_list) {
    ... # do something
  }

=head1 DESCRIPTION

This is a class to read and write 03modlist.data

=head1 METHODS

=head2 modules

List of modules.

=head2 module_count

Number of modules indexed in the file.

=head2 description

Short description of the file.

=head2 written_by

Name and version of software that wrote the file.

=head2 date

Date and time when the file was written.

=head2 parse

Parses the file and reurns its representation as a data structure.

=head1 METHODS FROM ROLES

=over

=item <CPAN::Index::API::Role::Reader/read_from_string>

=item <CPAN::Index::API::Role::Reader/read_from_file>

=item <CPAN::Index::API::Role::Reader/read_from_tarball>

=item <CPAN::Index::API::Role::Reader/read_from_repo_path>

=item <CPAN::Index::API::Role::Reader/read_from_repo_uri>

=item L<CPAN::Index::API::Role::Writer/filename>

=item L<CPAN::Index::API::Role::Writer/tarball_suffix>

=item L<CPAN::Index::API::Role::Writer/repo_path>

=item L<CPAN::Index::API::Role::Writer/template>

=item L<CPAN::Index::API::File::Role::Writer/content>

=item L<CPAN::Index::API::File::Role::Writer/ write_to_file>

=item L<CPAN::Index::API::File::Role::Writer/write_to_tarball>

=back

=cut

__DATA__
File:        [% $self->filename %]
Description: [% $self->description %]
Modcount:    [% $self->module_count %]
Written-By:  [% $self->written_by %]
Date:        [% $self->date %]

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
my $result = {};
my $primary = "modid";
for (@$CPAN::Modulelist::data){
my %hash;
@hash{@$CPAN::Modulelist::cols} = @$_;
$result->{$hash{$primary}} = \%hash;
}
$result;
}
$CPAN::Modulelist::cols = [
'modid',
'statd',
'stats',
'statl',
'stati',
'statp',
'description',
'userid',
'chapterid'
];

[%
    if ($self->module_count)
    {
        $OUT .= '$CPAN::Modulelist::data = [' . "\n";

        foreach my $module ($self->module_list) {
            $OUT .= sprintf "[\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s',\n'%s'\n],\n",
                $module->{name},
                $module->{development_stage} ? $module->{development_stage} : '?',
                $module->{support_level}     ? $module->{support_level}     : '?',
                $module->{language_used}     ? $module->{language_used}     : '?',
                $module->{interface_style}   ? $module->{interface_style}   : '?',
                $module->{public_license}    ? $module->{public_license}    : '?',
                $module->{description},
                $module->{author},
                $module->{chapterid},
        }

        $OUT .= "];\n"
    }
    else
    {
        $OUT .= '$CPAN::Modulelist::data = [];' . "\n";
    }
%]

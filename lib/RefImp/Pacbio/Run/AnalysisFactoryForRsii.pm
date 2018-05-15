package RefImp::Pacbio::Run::AnalysisFactoryForRsii;

use strict;
use warnings 'FATAL';

use Data::Dumper 'Dumper';
use File::Find 'find';
use List::Util;
use Path::Class;
use RefImp::Pacbio::Run::Analysis;
use XML::LibXML;

sub build {
    my ($class, $directory) = @_;

    die "No run directory given." if not $directory;
    die "Run directory given does not exist!" if not -d "$directory";

    my (@analyses);
    find(
        {
            wanted => sub{
                if ( /metadata\.xml$/) {
                    my $xml_info = _load_xml( $File::Find::name );
                    my $analysis = RefImp::Pacbio::Run::Analysis->new(
                        metadata_xml_file => file( $File::Find::name ),
                        %$xml_info,
                    );
                    push @analyses, $analysis;
                }
                elsif ( $File::Find::dir =~ /Analysis_Results/ and /\.h5$/ ) {
                    die "No analyses created to add analysis files!" if not @analyses;
                    $analyses[$#analyses]->add_analysis_file( file($File::Find::name) );
                }
            },
        },
        glob($directory->file('*')->stringify),
    );

    return if not @analyses;
    \@analyses;
}

sub _load_xml {
    my ($xml_file) = @_;

    my $dom = XML::LibXML->load_xml(location => "$xml_file");
    my $metadata_node = $dom->firstChild;
    if ( not $metadata_node ) {
        die "No metadata node found in $xml_file";
    }

    my $sample_node = List::Util::first { $_->nodeName eq 'Sample' } $metadata_node->childNodes;
    if ( not $sample_node ) {
        die "No sample node found!";
    }

    my $library_name = _load_from_parent_node($sample_node, 'Name');
    my $well = _load_from_parent_node($sample_node, 'WellName');

    my $sample_name = $library_name;
    my $well_without_zeros = $well;
    $well_without_zeros =~ s/0//g;
    $sample_name =~ s/_$well_without_zeros$//;

    {
        sample_name => $sample_name,
        library_name => $library_name,
        plate_id => _load_from_parent_node($sample_node, 'PlateId'),
        version => _load_from_parent_node($metadata_node, 'InstCtrlVer'),
        well => $well,
    };
}

sub _load_from_parent_node {
    my ($parent_node, $node_name) = @_;
    die "No parent node given!" if not $parent_node;
    die "No node name node given!" if not $node_name;

    my $node = List::Util::first { $_->nodeName eq $node_name } $parent_node->childNodes;
    if ( not $node ) {
        die "No $node_name node found!";
    }

    my $version = $node->to_literal;
    if ( not $version ) {
        die "No info found in $node_name node!";
    }
    $version;
}

1;

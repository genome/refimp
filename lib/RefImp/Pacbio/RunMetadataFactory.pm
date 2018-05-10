package RefImp::Pacbio::RunMetadataFactory;

use strict;
use warnings 'FATAL';

use Data::Dumper 'Dumper';
use List::Util;
use RefImp::Pacbio::RunMeta;
use XML::LibXML;

sub build {
    my ($class, $xml_file) = @_;

    die "No metadata XML file given!" if not $xml_file;
    die "Metadata XML file does not exist: $xml_file" if not -s "$xml_file";

    my $xml_info = _load_xml($xml_file);
    RefImp::Pacbio::RunMeta->new(
        metadata_xml_file => $xml_file,
        %$xml_info,
    );
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

    {
        sample_name => _load_from_parent_node($sample_node, 'Name'),
        version => _load_from_parent_node($metadata_node, 'InstCtrlVer'),
        well => _load_from_parent_node($sample_node, 'WellName'),
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

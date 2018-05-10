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

    my $sample_name = _load_sample_info($metadata_node);
    my $version = _load_software_version($metadata_node);
    {
        sample_name => $sample_name,
        version => $version,
    };
}

sub _load_sample_info {
    my ($metadata_node) = @_;

    my $sample_node = List::Util::first { $_->nodeName eq 'Sample' } $metadata_node->childNodes;
    if ( not $sample_node ) {
        die "No sample node found!";
    }

    my $sample_name_node = List::Util::first { $_->nodeName eq 'Name' } $sample_node->childNodes;
    if ( not $metadata_node ) {
        die "No sample name node found!";
    }

    my $sample_name = $sample_name_node->to_literal;
    if ( not $sample_name ) {
        die "No sample name found in sample name node!";
    }
    $sample_name;
}

sub _load_software_version {
    my ($metadata_node) = @_;

    my $node = List::Util::first { $_->nodeName eq 'InstCtrlVer' } $metadata_node->childNodes;
    if ( not $node ) {
        die "No in node found!";
    }

    my $version = $node->to_literal;
    if ( not $version ) {
        die "No version found in InstCtrlVer node!";
    }
    $version;
}
1;

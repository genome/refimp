package RefImp::Pacbio::RunMetadata;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
RefImp::Pacbio::RunMetadata->mk_accessors(qw/ xml_file sample_name /);

use Data::Dumper 'Dumper';
use List::Util;
use XML::LibXML;

sub new {
    my ($class, $xml_file) = @_;

    die "No metadata XML file given!" if not $xml_file;
    die "Metadata XML file does not exist: $xml_file" if not -s "$xml_file";

    my $self = {
        xml_file => $xml_file,
    };
    bless $self, $class;
    $self->_load_xml;
    $self;
}

sub _load_xml {
    my ($self) = @_;

    my $xml_file = $self->xml_file;
    my $dom = XML::LibXML->load_xml(location => "$xml_file");
    my $metadata_node = $dom->firstChild;
    if ( not $metadata_node ) {
        warn "No metadata node found in $xml_file";
        return;
    }

    my $sample_node = List::Util::first { $_->nodeName eq 'Sample' } $metadata_node->childNodes;
    if ( not $sample_node ) {
        warn "No sample node found in $xml_file";
        return;
    }

    my $sample_name_node = List::Util::first { $_->nodeName eq 'Name' } $sample_node->childNodes;
    if ( not $metadata_node ) {
        warn "No sample name node found in $xml_file";
        return;
    }

    my $sample_name = $sample_name_node->to_literal;
    if ( not $sample_name ) {
        warn "No sample name found in sample name node in $xml_file";
        return;
    }
    $self->sample_name($sample_name);
}

1;

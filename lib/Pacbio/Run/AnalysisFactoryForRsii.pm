package Pacbio::Run::AnalysisFactoryForRsii;

use strict;
use warnings 'FATAL';

use Data::Dumper 'Dumper';
use File::Find 'find';
use List::Util;
use Path::Class;
use Pacbio::Run::Analysis;
use XML::LibXML;

sub build {
    my ($class, $directory) = @_;

    die "No run directory given." if not $directory;
    die "Run directory given does not exist! $directory" if not -d "$directory";

    my (@analyses);
    find(
        {
            wanted => sub{
                if ( /metadata\.xml$/) {
                    my $xml_info = _load_xml( $File::Find::name );
                    my $analysis = Pacbio::Run::Analysis->new(
                        metadata_xml_file => file( $File::Find::name ),
                        %$xml_info,
                    );
                    push @analyses, $analysis;
                }
                elsif ( $File::Find::dir =~ /Analysis_Results/ and /\.h5$/ ) {
                    die "No analyses created to add analysis files!" if not @analyses;
                    $analyses[$#analyses]->add_analysis_files( file($File::Find::name) );
                }
            },
        },
        glob($directory->file('*')->stringify),
    );

    return if not @analyses;
    \@analyses;
}

sub build_from_analysis_directory {
    my ($class, $directory) = @_;

    die "No analysis directory given." if not $directory;
    die "Analysis directory given does not exist! $directory" if not -d "$directory";

    my ($metadata_xml_file, @analysis_files);
    find(
        {
            wanted => sub{
                if ( /metadata\.xml$/) {
                    die "Found more than one metadata XML in $directory" if $metadata_xml_file;
                    $metadata_xml_file = $File::Find::name;
                }
                elsif ( $File::Find::dir =~ /Analysis_Results/ and /\.h5$/ ) {
                    push @analysis_files, $File::Find::name;
                }
            },
        },
        glob($directory->file('*')->stringify),
    );

    die "Failed to find analysis metadata xml in directory: $directory" if !$metadata_xml_file;
    die "Failed to find analysis files in directory: $directory" if !@analysis_files;

    my $xml_info = _load_xml($metadata_xml_file);
    my $analysis = Pacbio::Run::Analysis->new(
        metadata_xml_file => file($metadata_xml_file),
        %$xml_info,
    );
    $analysis->add_analysis_files( map { file($_) } sort { $a cmp $b } @analysis_files );
    $analysis;
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

    {
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

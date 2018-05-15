package RefImp::Pacbio::Run::AnalysisFactoryForSequel;

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
                if ( /metadata\.xml$/ and ! /run/ ) {
                    my $xml_info = _load_xml( $File::Find::name );
                    my $analysis = RefImp::Pacbio::Run::Analysis->new(
                        metadata_xml_file => file( $File::Find::name ),
                        %$xml_info,
                    );
                    push @analyses, $analysis;
                }
                elsif ( /\.subreads\.bam$/ ) {
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

    my %info;
    my ($collection) = $dom->getElementsByTagName('pbmeta:Collections');
    if ( not $collection ) {
        die "No collection node found in $xml_file";
    }

    my ($collection_metadata) = $collection->getElementsByTagName('pbmeta:CollectionMetadata');
    if ( not $collection_metadata ) {
        die "No collection metadata node found in $xml_file";
    }

    my ($run_details_node) = $collection_metadata->getElementsByTagName('pbmeta:RunDetails');
    if ( not $run_details_node ) {
        die "No run details node found in $xml_file";
    }
    my ($run_name_node) = $collection_metadata->getElementsByTagName('pbmeta:Name');
    if ( not $run_name_node ) {
        die "No run name node found in $xml_file";
    }
    $info{plate_id} = $run_name_node->to_literal;

    my ($version_node) = $collection_metadata->getElementsByTagName('pbmeta:InstCtrlVer');
    if ( not $version_node ) {
        die "No sample node found in $xml_file";
    }
    $info{version} = $version_node->to_literal;

    my ($sample_node) = $collection_metadata->getElementsByTagName('pbmeta:WellSample');
    if ( not $sample_node ) {
        die "No sample node found in $xml_file";
    }
    $info{library_name} = $sample_node->getAttribute('Name');
    my @tokens = split(/_/, $info{library_name});
    pop @tokens;
    $info{sample_name} = join('_', @tokens);

    my ($well_name_node) = $collection_metadata->getElementsByTagName('pbmeta:WellName');
    if ( not $well_name_node ) {
        die "No well name node found in $xml_file";
    }
    $info{well} = $well_name_node->to_literal;

    \%info;
}

1;

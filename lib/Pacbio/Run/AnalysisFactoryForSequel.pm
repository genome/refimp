package Pacbio::Run::AnalysisFactoryForSequel;

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
    die "Run directory given does not exist!" if not -d "$directory";

    my (%well_meta_xml_files, %well_analysis_files);
    find(
        {
            wanted => sub{
                if ( /metadata\.xml$/ and ! /run/ ) {
                    $well_meta_xml_files{ $File::Find::dir } = file( $File::Find::name );
                }
                elsif ( /\.subreads\.bam$/ ) {
                    push @{$well_analysis_files{ $File::Find::dir }}, file($File::Find::name);
                }
            },
        },
        glob($directory->file('*')->stringify),
    );

    die "No meata data xml files found in $directory" if not %well_meta_xml_files;

    my (@analyses);
    for my $well_dir ( sort keys %well_meta_xml_files ) {
        die "No analysis files for $well_dir" if not exists $well_analysis_files{$well_dir};
        my $xml_info = _load_xml( $well_meta_xml_files{$well_dir} );
        my $analysis = Pacbio::Run::Analysis->new(
            metadata_xml_file => $well_meta_xml_files{$well_dir},
            %$xml_info,
        );
        $analysis->add_analysis_files(sort @{$well_analysis_files{$well_dir}});
        push @analyses, $analysis;
    }

    return if not @analyses;
    \@analyses;
}

sub _load_xml {
    my ($xml_file) = @_;

    my $dom = XML::LibXML->load_xml(location => "$xml_file");

    my ($data_model) = $dom->getElementsByTagName('pbdm:PacBioDataModel');
    if ( not $data_model ) {
        ($data_model) = $dom->getElementsByTagName('PacBioDataModel');
    }

    if ( not $data_model ) {
        die "Could not find PacBioDataModel node!"
    }

    my $version = $data_model->getAttribute('Version');
    die "No version found in PacBioDataModel node!" if not $version;
    my $node_names = _node_names_for_version($version);

    my %info;
    my ($collection) = $dom->getElementsByTagName( $node_names->{collections} );
    if ( not $collection ) {
        die "No collection node found in $xml_file";
    }

    my ($collection_metadata) = $collection->getElementsByTagName( $node_names->{collection_metadata} );
    if ( not $collection_metadata ) {
        die "No collection metadata node found in $xml_file";
    }

    my ($run_details_node) = $collection_metadata->getElementsByTagName( $node_names->{run_details} );
    if ( not $run_details_node ) {
        die "No run details node found in $xml_file";
    }
    my ($run_name_node) = $collection_metadata->getElementsByTagName( $node_names->{run_name} );
    if ( not $run_name_node ) {
        die "No run name node found in $xml_file";
    }
    $info{plate_id} = $run_name_node->to_literal;

    my ($version_node) = $collection_metadata->getElementsByTagName( $node_names->{instrument_control_version} );
    if ( not $version_node ) {
        die "No sample node found in $xml_file";
    }
    $info{version} = $version_node->to_literal;

    my ($sample_node) = $collection_metadata->getElementsByTagName( $node_names->{well_sample} );
    if ( not $sample_node ) {
        die "No sample node found in $xml_file";
    }
    $info{library_name} = $sample_node->getAttribute('Name');

    my ($well_name_node) = $collection_metadata->getElementsByTagName( $node_names->{well_name} );
    if ( not $well_name_node ) {
        die "No well name node found in $xml_file";
    }
    $info{well} = $well_name_node->to_literal;

    \%info;
}

sub _node_names_for_version {
    my ($version) = @_;

    if ( $version eq '4.0.0' ) {
        return {
            collections => 'pbmeta:Collections',
            collection_metadata => 'pbmeta:CollectionMetadata',
            run_details => 'pbmeta:RunDetails',
            run_name => 'pbmeta:Name',
            instrument_control_version => 'pbmeta:InstCtrlVer',
            well_sample => 'pbmeta:WellSample',
            well_name => 'pbmeta:WellName',
        }
    }
    elsif ( $version eq '4.0.1' ) {
        return {
            collections => 'Collections',
            collection_metadata => 'CollectionMetadata',
            run_details => 'RunDetails',
            run_name => 'Name',
            instrument_control_version => 'InstCtrlVer',
            well_sample => 'WellSample',
            well_name => 'WellName',
        }
    }
    else {
        die "Unknown PacBio Data Model version: $version!";
    }
}

1;

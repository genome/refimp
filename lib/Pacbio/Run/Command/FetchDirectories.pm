package Pacbio::Run::Command::FetchDirectories;

use strict;
use warnings 'FATAL';

use Data::Dumper 'Dumper';
use Path::Class;
use XML::LibXML;

use Pacbio::Run;

class Pacbio::Run::Command::FetchDirectories {
    is => 'Command::V2',
	has => {
		xml_file=> {
			is => 'Text',
			doc => "The dataset xml file output from smrt link.",
		},
	},
	doc => 'parse run directories from smrt link xml',
};

sub help_detail { $_[0]->__meta__->doc."\n\n** Only works on Sequel runs. Submit issue for RSII Runs with XML example **\n" }

sub execute {
    my ($self) = @_;

    my $xml_file = $self->xml_file;
    my $dom = XML::LibXML->load_xml(location => "$xml_file");

    my ($subread_set_node) = $dom->getElementsByTagName('pbds:SubreadSet');
    if ( not $subread_set_node) {
        die "No suread set node found in $xml_file";
    }

    my ($external_resources_node) = $subread_set_node->findnodes('./pbbase:ExternalResources');
    if ( not $external_resources_node) {
        die "No external resources node found in $xml_file";
    }

    my @external_resources = $external_resources_node->findnodes('./pbbase:ExternalResource');
    if ( not @external_resources ) {
        die "No external resources found in $xml_file";
    }

    my (@run_dirs, @non_existing_dirs);
    for my $er ( @external_resources ) {
        my $run_dir = file( $er->getAttribute('ResourceId') )->parent->parent->absolute;
        if ( -d "$run_dir" ) {
            push @run_dirs, $run_dir;
        }
        else {
            push @non_existing_dirs, $run_dir;
        }
    }

    if ( @non_existing_dirs ) {
        $self->warning_message("These run directories do not exist:\n %s", join("\n ", List::MoreUtils::uniq(@non_existing_dirs)));
    }

    if ( @run_dirs ) {
        $self->status_message("\nFound these exiting run directories from metadata XML:");
        print join("\n", List::MoreUtils::uniq @run_dirs)."\n";
    }
    else {
        $self->fatal_message('Failed to find any existing run directories in metadata XML');
    }

    1;
}

sub Xexecute {
    my ($self) = @_;

    my $xml_file = $self->xml_file;
    my $dom = XML::LibXML->load_xml(location => "$xml_file");

    my ($datasets_node) = $dom->getElementsByTagName('pbds:DataSets');
    if ( not $datasets_node) {
        die "No datasets node found in $xml_file";
    }

    my %info;
    my @datasets = $datasets_node->getElementsByTagName('pbds:DataSet');
    if ( not @datasets ) {
        die "No datasets found in datasets node in $xml_file";
    }

    for my $ds ( @datasets ) {
        my ($ds_metadata) = $ds->getElementsByTagName('pbds:DataSetMetadata');
        if ( not $ds_metadata ) {
            die "No data set metadata node found in $xml_file";
        }

        my ($collection) = $ds_metadata->getElementsByTagName('pbmeta:Collections');
        if ( not $collection ) {
            die "No collection node found in $xml_file";
        }

        my ($collection_metadata) = $collection->getElementsByTagName('pbmeta:CollectionMetadata');
        if ( not $collection_metadata ) {
            die "No collection metadata node found in $xml_file";
        }

        my ($primary_node) = $collection_metadata->getElementsByTagName('pbmeta:Primary');
        if ( not $primary_node ) {
            die "No primary node found in collection metadata $xml_file";
        }

        my ($output_options) = $collection_metadata->getElementsByTagName('pbmeta:OutputOptions');
        if ( not $output_options ) {
            die "No output options found in primary found in $xml_file";
        }

        my ($uri) = $collection_metadata->getElementsByTagName('pbmeta:CollectionPathUri');
        if ( not $uri ) {
            die "No colection path uri node found in output options in $xml_file";
        }

        my ($sample_node) = $collection_metadata->getElementsByTagName('pbmeta:WellSample');
        if ( not $sample_node ) {
            die "No sample node found in $xml_file";
        }

        push @{$info{ dir($uri->to_literal)->parent->stringify }}, $sample_node->getAttribute('Name');

    }

    print Dumper \%info;
    1;
}

1;

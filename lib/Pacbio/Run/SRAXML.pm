package Pacbio::Run::SRAXML;

use strict;
use warnings 'FATAL';

use Path::Class ('file','dir');
use XML::LibXML;
use XML::Compile::Schema;
use XML::Compile::Util;
use Moose;

sub struct_to_xml {
    my ( $self, $element, $struct ) = @_;

    my $xsd        = [ sra_xsd_files() ];
    my $xml_schema = XML::Compile::Schema->new($xsd) or die 'new failed';
    my $xml_writer = $xml_schema->compile( 'WRITER' => uc($element), ) or die 'compile failed';
    my $dom        = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    my $xml_element = $xml_writer->( $dom, $struct, ) or die 'writer failed';
    $dom->setDocumentElement($xml_element);
    $element =~ s/_set$//;

    $xml_element->setAttributeNS(
        XML::Compile::Util::SCHEMA2001i(),
        "xsi:noNamespaceSchemaLocation",
        sra_xsd_uri_for($element),
    );
    my $xml = $dom->toString(1);
    return $xml;
}

sub sra_xsd_file_types {
    qw( analysis common experiment run sample study submission );
}
sub sra_xsd_files {
    return map { sra_xsd_file_for($_) } sra_xsd_file_types();
}
sub sra_xsd_file_for {
    my $type = shift or die 'need a file type';
    return sra_xsd_dir()->file( 'SRA.' .$type .'.xsd' );
}
sub sra_xsd_dir {
    my $dir = file(__FILE__)->absolute->dir;
    return dir($dir,'SRAXML','xsd');
}
sub sra_xsd_uri_for {
    my $type = shift or die 'need a file type';
    return 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.' . $type . '.xsd?view=co';
}
sub get_xml_basenode_name {
    my $self = shift;
    my $xml_string = shift;
    my $dom = XML::LibXML->load_xml(string => $xml_string);
    return $dom->documentElement()->nodeName;
}

sub write_tar_file_to_dir {
    my $proto  = shift;
    my %params = @_;
    my $dir = $params{dir};
    my $name = $params{name};

    my $subdir = dir($dir,$name);
    mkdir $subdir if (!-d $subdir);
    for my $xml (@{$params{xml}}) {

        my $xml_type = lc($proto->get_xml_basenode_name($xml));
        $xml_type =~ s/_set//g;

        my $file = file($subdir, $name .'.' .$xml_type .'.xml');
        my $fh = $file->openw() or die $!;
        print $fh $xml;
        close $fh;
    }

    #tar it up
    my $tar = file($dir,$name .'.tar');
    my $cmd = "cd $dir; tar --create " .$name .' --file ' .$tar->basename;
    my $tar_output = qx{$cmd};
    die "tar failed:\n command: $cmd\n output: $tar_output\n" unless $? == 0;

    return $tar;
}

1;

package RefImp::Assembly::Command::Submission::TblToAsn;

use strict;
use warnings 'FATAL';

use File::Spec;
use File::Temp;
use IO::File;
use Path::Class 'dir';

class RefImp::Assembly::Command::Submission::TblToAsn {
    is => 'Command::V2',
    has => {
        submission_yml => { is => 'Text', doc => 'Assembly submission object' },
        output_directory => { is => 'Text', doc => 'File system location to put output of tabl2asn', },
    },
    has_optional_transient => {
        fasta_files => { is => 'Text', is_many => 1, },
        _output_directory => { is => 'Path::Class::Dir', },
        sqn_files => { is => 'Text', is_many => 1, },
        submission => { is => 'RefImp::Assembly::Submission', },
    },
    has_optional_calculated => {
        comment_file => { calculate_from => [qw/ _output_directory /], calculate => q| $_output_directory->file('COMMENT'); |, },
        discrepancy_report_path => { calculate_from => [qw/ results_path /], calculate => q| $results_path->file('discrepancy_report'); |, },
        results_path => { calculate_from => [qw/ _output_directory /], calculate => q| $_output_directory->subdir('RESULTS'); |, },
        template_file => { calculate_from => [qw/ _output_directory /], calculate => q| $_output_directory->file('template.sbt'); |, },
    },
    doc => 'run tbl2asn on a submission',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    $self->status_message('TBL TO ASN...');
    $self->submission( RefImp::Assembly::Submission->define_from_yml($self->submission_yml) );
    $self->status_message('Submission: %s', $self->submission->__display_name__);
    $self->_output_directory( dir( $self->output_directory) );
    $self->status_message('Output directory: %s', $self->_output_directory);

    $self->write_comment_file;
    $self->write_template_file;
    $self->split_fasta_files;
    $self->write_cmt_files;
    $self->run_tbl2asn;

    $self->status_message('TBL TO ASN...OK');
    1;
}

sub write_comment_file {
    my $self = shift;
    $self->status_message("Create 'COMMENT' file...");

    my $file = $self->comment_file;
    $self->status_message("COMMENT file: %s", $file);
    my $fh = $file->openw;
    $self->fatal_message('Failed to open %s for writing!', $file) if not $fh;
    my $content = $self->submission->release_notes;
    $fh->print($content);
    $fh->close;

    $self->status_message("Create 'COMMENT' file...OK");
}

sub write_template_file {
    my $self = shift;
    $self->status_message("Create  'template.sbt' file...");

    my $file = $self->template_file;
    $self->status_message("Template file: %s", $file);
    my $fh = $file->openw;
    $self->fatal_message('Failed to open %s for writing!', $file) if not $fh;
    my $content = $self->submission_template;
    $fh->print($content);
    $fh->close;

    $self->status_message("Create 'template.sbt' file...OK");
}

sub submission_template {
    my $self = shift;

    my $string = $self->submission->info_for('authors');
    $self->fatal_message('No authors for submission!') if not $string;
    my $authors = join("\n          ", map { '{ '.$_.' } ,' } $self->format_names($string));

    $string = $self->submission->info_for('contact');
    $self->fatal_message('No contact for submission!') if not $string;
    my ($contact) = $self->format_names($string);

    my $bioproject = $self->submission->bioproject;
    my $bioproject_uid = $self->submission->bioproject_uid;
    my $biosample = $self->submission->biosample;
    my $biosample_uid = $self->submission->biosample_uid;

    return <<EOF;
Submit-block ::= {
  contact {
    contact {
      $contact ,
      affil
        std {
          affil "Washington University School of Medicine" ,
          div "McDonnell Genome Institute" ,
          city "St. Louis" ,
          sub "MO" ,
          country "USA" ,
          street "4444 Forest Park" ,
          email "mgi-submission\@gowustl.onmicrosoft.com" ,
          postal-code "63108" } } } ,
  cit {
    authors {
      names
        std {
          $authors } ,
      affil
        std {
          affil "Washington University School of Medicine" ,
          div "McDonnell Genome Institute" ,
          city "St. Louis" ,
          sub "MO" ,
          country "USA" ,
          street "4444 Forest Park" ,
          email "mgi-submission\@gowustl.onmicrosoft.com" ,
          postal-code "63108" } } },
    subtype new ,
}

Seqdesc ::= user {
    type str "DBLink",
    data {
        {
            label str "BioProject",
            num $bioproject_uid,
            data strs {
                "$bioproject"
            }
        },
        {
            label str "BioSample",
            num $biosample_uid,
            data strs {
                "$biosample"
            }
        }
    }
}

EOF
}

sub structured_comments {
    my $self = shift;

    my $submission = $self->submission;
    my @comments;
    for my $attr ( RefImp::Assembly::SubmissionInfo->required_attributes_for_structured_comments ) {
        push @comments, join("\t", join(' ', map { ucfirst } split('_', $attr)), $submission->info_for($attr));
    }

    for my $attr ( RefImp::Assembly::SubmissionInfo->optional_attributes_for_structured_comments ) {
        my $val = $submission->info_for($attr);
        next if not defined $val;
        push @comments, join("\t", join(' ', map { ucfirst } split('_', $attr)), $val);
     }

     join("\n", join("\t", 'StructuredCommentPrefix', '##Genome-Assembly-Data-START##'), sort @comments)."\n";
}

sub split_fasta_files {
    #$header =~ s/^Contig(\S+)/$version-$1/;
    my $self = shift;
    $self->status_message('Splitting fasta files...');

    my @fasta_files;
    for my $type (qw/ contigs supercontigs /) {
        my $fasta_file = $self->submission->path_for($type."_file");
        next if not $fasta_file;

        my $splitter = RefImp::Assembly::Command::Submission::SplitFasta->execute(
            fasta_file => $fasta_file,
            output_fasta_file_pattern => File::Spec->join($self->_output_directory, join('.', $type, '%02d', 'fsa')),
            max_seq_count => 10_000,
            max_file_size => 1_800_000_000,
        );
        $self->fatal_message('Failed to split fasta file!') if not $splitter->result;
        push @fasta_files, $splitter->output_fasta_files;
    }

    $self->fasta_files(\@fasta_files);
    $self->status_message('Splitting fasta files...OK');
}

sub write_cmt_files {
    my $self = shift;
    $self->status_message('Writing "cmt" files for each "fsa" file...');

    my $content = $self->structured_comments;

    for my $file ( $self->fasta_files ) {
        $file =~ s/.fsa$/\.cmt/;
        my $fh = IO::File->new($file, 'w');
        $self->fatal_message('Failed to open %s for writing!', $file) if not $fh;
        $fh->print($content);
        $fh->close;
    }

    $self->status_message('Writing "cmt" files for each "fsa" file...OK');
}

sub write_file {
    my $self = shift;
    my ($file_name, $method_name) = @_;

    my $fh = $self->_output_directory->file($file_name)->openw;
    unless ($fh->print( $self->$method_name ) ) {
        $self->fatal_message('problem writing '. $file_name);
    }

    return 1;
}

sub format_names {
    my ($self, $string) = @_;
    $self->fatal_message('No names string given to format!') if not $string;

    my @formatted_names;
    foreach my $name ( split(/;\s?/, $string) ) {
        my $parsed_name = RefImp::User->parse_name($name);
        push @formatted_names, sprintf(
            'name name { last "%s" , first "%s" , initials "%s" }',
            $parsed_name->{last},
            $parsed_name->{first},
            $parsed_name->{initials},
        );
    }

    @formatted_names;
}

sub run_tbl2asn {
    my $self = shift;
    $self->status_message('Run Tbl2Asn...');

    my @tbl2asn_cmd = $self->tbl2asn_command;
    my $results_path = $self->results_path;
    $results_path->mkpath or $self->fatal_message('Failed to mkpath for %s!', $results_path);
    $results_path->file('tbl2asn_command')->openw->say( join(' ', @tbl2asn_cmd) );
    
    $self->status_message('Running: %s', join(' ', @tbl2asn_cmd));
    my $rv = system(@tbl2asn_cmd);
    $self->fatal_message('Failed to run tbl2asn: %s', $!) if $rv != 0;

    my @sqn_files = glob( $self->results_path->file('*.sqn') );
    $self->fatal_message('Did not find any SQN files in %s', $results_path) if not @sqn_files;
    $self->sqn_files(\@sqn_files);

    $self->status_message('Run Tbl2Asn...OK');
}

sub tbl2asn_command {
    my $self = shift;

    my @cmd = (
        # Command
        "tbl2asn",

        # Path to Files [String]  Optional
        '-p', $self->_output_directory->stringify,

        # Path for Results [String]  Optional
        '-r', $self->results_path->stringify,

        # Template File [File In]  Optional
        '-t', $self->template_file->stringify,

        # Read FASTAs as Set [T/F]  Optional
        '-s',

        # Verification: (combine any of the following letters)
        # v Validate with Normal Stringency
        # r Validate without Country Check
        # c BarCode Validation
        # b Generate GenBank Flatfile
        # g Generate Gene Report
        '-V', 'vb',

        # Discrepancy Report Output File [File Out]  Optional
        '-Z', $self->discrepancy_report_path,

        # Extra Flags (combine any of the following letters)
        # A Automatic definition line generator
        # C Apply comments in .cmt files to all sequences
        # E Treat like eukaryota in the Discrepancy Report
        '-X', 'AC',

        # Source Qualifiers [String]  Optional
        '-j', $self->source_qualifiers,

        # Comment File [File In]  Optional
        '-Y', $self->comment_file,
    );

    my $additional_params = $self->submission->info_for('tbl2asn_params');
    if ( $additional_params ) {
        push @cmd, split(/\s+/, $additional_params);
    }

    @cmd;
}

sub source_qualifiers {
    my $self = shift;

    my $submission = $self->submission;
    my $taxon = $submission->taxon;

    my $format = '[%s=%s]'; # format: [modifier=text]
    my @source_qualifiers = sprintf($format, 'organism', ucfirst $taxon->species_name);
    push @source_qualifiers, sprintf($format, 'strain', $taxon->strain_name) if $taxon->strain_name;
    push @source_qualifiers, sprintf($format, 'tech', 'wgs');
    # Potential other qualifiers: [host=Homo sapiens] [isolation-source=Stool sample of individual with bacteremia] [country=USA: MO]

    "'".join(' ', @source_qualifiers)."'";
}

1;

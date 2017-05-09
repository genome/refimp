package RefImp::Assembly::Submission::TblToAsn;

use strict;
use warnings 'FATAL';

use File::Spec;
use File::Temp;
use IO::File;
use Path::Class;

class RefImp::Assembly::Submission::TblToAsn {
    is => 'Command::V2',
    has => {
        submission => { is => 'RefImp::Assembly::Submission', },
    },
    has_optional_transient => {
        fasta_files => { is => 'Text', is_many => 1, },
        sqn_files => { is => 'Text', is_many => 1, },
        tempdir => { is => 'Path::Class', },
    },
    has_optional_calculated => {
        comment_file => { calculate_from => [qw/ tempdir /], calculate => q| $tempdir->file('COMMENT'); |, },
        discrepancy_report_path => { calculate_from => [qw/ results_path /], calculate => q| $results_path->file('discrepancy_report'); |, },
        results_path => { calculate_from => [qw/ tempdir /], calculate => q| $tempdir->subdir('RESULTS'); |, },
        template_file => { calculate_from => [qw/ tempdir /], calculate => q| $tempdir->file('template.sbt'); |, },
    },
};

sub results_dir_path { $_[0]->tempdir->subdir('RESULTS') }

sub execute {
    my $self = shift;
    $self->status_message('TBL TO ASN...');
    $self->status_message('Submission: %s', $self->submission->__display_name__);

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $self->tempdir( Path::Class::dir($tempdir) );
    $self->results_path->mkpath;

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

    my $authors = $self->submission_authors;
    my $bioproject = $self->submission->bioproject;
    my $bioproject_uid = $self->submission->bioproject_uid;
    my $biosample = $self->submission->biosample;
    my $biosample_uid = $self->submission->biosample_uid;

    return <<EOF;
Submit-block ::= {
  contact {
    contact {
      name
        name {
          last "Wilson" ,
          first "Rick" ,
          initials "R.K." } ,
      affil
        std {
          affil "Washington University School of Medicine" ,
          div "McDonnell Genome Institute" ,
          city "St. Louis" ,
          sub "MO" ,
          country "USA" ,
          street "4444 Forest Park" ,
          email "submissions\@genome.wustl.edu" ,
          postal-code "63108" } } } ,
  cit {
    authors {
      names
        std {
            $authors
            } ,
      affil
        std {
          affil "Washington University School of Medicine" ,
          div "McDonnell Genome Institute" ,
          city "St. Louis" ,
          sub "MO" ,
          country "USA" ,
          street "4444 Forest Park" ,
          email "submissions\@genome.wustl.edu" ,
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
    my $comment = join("\t", 'StructuredCommentPrefix', '##Genome-Assembly-Data-START##')."\n";
    $comment .= join("\t", 'Assembly Method', $submission->info_for('assembly_method'))."\n";
    my $polishing_method = $submission->info_for('polishing_method');
    $comment .= join("\t", 'Polishing Method', $polishing_method)."\n" if $polishing_method ne 'NA';
    $comment .= join("\t", 'Genome Coverage', $submission->info_for('coverage'))."\n";
    $comment .= join("\t", 'Sequencing Technology', $submission->info_for('sequencing_technology'))."\n";

    $comment;
}

sub split_fasta_files {
    #$header =~ s/^Contig(\S+)/$version-$1/;
    my $self = shift;
    $self->status_message('Splitting fasta files...');

    my @fasta_files;
    for my $type (qw/ contigs supercontigs /) {
        my $fasta_file = $self->submission->path_for($type."_file");
        next if not $fasta_file;

        my $splitter = RefImp::Assembly::Submission::SplitFasta->execute(
            fasta_file => $fasta_file,
            output_fasta_file_pattern => File::Spec->join($self->tempdir, join('.', $type, '%02d', 'fsa')),
            max_seq_count => 10_000,
            max_file_size => 1_800_000,
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

    my $fh = $self->tempdir->file($file_name)->openw;
    unless ($fh->print( $self->$method_name ) ) {
        $self->fatal_message('problem writing '. $file_name);
    }

    return 1;
}

sub submission_authors {
    my $self = shift;

    my $authors_string = $self->submission->info_for('authors');
    $self->fatal_message('No submission authors!') if not $authors_string;

    my @submission_authors;
    foreach my $author ( split(/,/, $authors_string) ) {
        my @name_parts = split /[ \.]/, $author;

        my $first = shift @name_parts;
        my $last  = pop @name_parts;
        my @initials = map {"$_."} map {uc $_} map {m/^(.)/} ($first, @name_parts);

        push @submission_authors, sprintf(
            '{ name name { last "%s" , first "%s" , initials "%s" } } ,',
            $last,
            $first,
            join('', @initials),
        );
    }

    join("\n", @submission_authors);
}

sub run_tbl2asn {
    my $self = shift;
    $self->status_message('Run Tbl2Asn...');

    my @tbl2asn_cmd = $self->tbl2asn_command;
    my $results_path = $self->results_path;
    $results_path->file('tbl2asn_command')->openw->say( join(' ', @tbl2asn_cmd) );
    
    $self->status_message('Running: %s', join(' ', @tbl2asn_cmd));
    my $rv = system(@tbl2asn_cmd);
    $self->fatal_message('Failed to run tbl2asn: %s', $!) if $rv != 0;

    my @sqn_files = glob( $self->results_dir_path->file('*.sqn') );
    $self->fatal_message('Did not find any SQN files in %s', $results_path) if not @sqn_files;
    $self->sqn_files(\@sqn_files);

    $self->status_message('Run Tbl2Asn...OK');
}

sub tbl2asn_command {
    my $self = shift;

    # TODO move to common place!
    my $pkg_path = File::Spec->join( split('::', __PACKAGE__) );
    $pkg_path .= '.pm';
    my $bin = $INC{$pkg_path};
    $bin =~ s#$pkg_path##;
    $bin =~ s#lib#bin#;
    my $tbl2asn = File::Spec->join($bin, "tbl2asn.linux64");

    return (
        # Command
        $tbl2asn,

        # Path to Files [String]  Optional
        '-p', $self->tempdir,

        # Path for Results [String]  Optional
        '-r', $self->results_dir_path,

        # Template File [File In]  Optional
        '-t', $self->template_file,

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
}

sub source_qualifiers {
    my $self = shift;

    my $submission = $self->submission;
    my $taxon = $submission->taxon;

    my $format = '[%s=%s]'; # format: [modifier=text]
    my @source_qualifiers = sprintf($format, 'organism', $taxon->species_name);
    push @source_qualifiers, sprintf($format, 'strain', $taxon->strain_name) if $taxon->strain_name;
    push @source_qualifiers, sprintf($format, 'tech', 'wgs');
    # Potential other qualifiers: [host=Homo sapiens] [isolation-source=Stool sample of individual with bacteremia] [country=USA: MO]

    "'".join(' ', @source_qualifiers)."'";
}

1;

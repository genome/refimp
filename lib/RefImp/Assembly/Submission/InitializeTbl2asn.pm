package GSC::PSE::InitializeTbl2asn;

use Moose;
use warnings FATAL => 'all';
use Path::Class qw(file dir);
use File::Copy  qw(copy);
use JSON qw(decode_json);
use POSIX qw(ceil);
use List::Util qw(max);

########################################
### BEGIN 'GSC::PSE::Role::RequiresAllocation'
########################################

sub derive_allocation_path { 'initialize_tbl2asn-'. shift->id }
sub disk_group_name {'submissions_staging'}
sub space_needed {1000}

########################################
### END 'GSC::PSE::Role::RequiresAllocation'
########################################

has file_count => (
                   is       => 'ro',
                   isa      => 'Int',
                   traits   => ['Counter'],
                   required => 1,
                   lazy     => 1,
                   default  => 0,
                   handles  => {
                                increase_file_count => 'inc',
                               },
                  );

sub get_genbank_assembly_submission {
    shift->get_prior_pse->get_genbank_assembly_submission }

sub output_agp_file_path {
    my ($self, $agp_path_obj) = @_;
    my $gbas = $self->get_genbank_assembly_submission;
    my $name;
    if( scalar(@{[$gbas->get_file_sets()]}) > 1 ) {
        $name = $agp_path_obj->basename;
    } else {
        $name = $self->get_genbank_assembly_submission->version . '.agp';
    }
    return $self->allocation_absolute_path->file($name);
}

sub confirm {
    my $self = shift;
    return unless $self->SUPER::confirm;

    $self->status_message(
        "allocation path: " 
        . $self->allocation_absolute_path->stringify
    );

    $self->allocation_absolute_path->mkpath()
        unless -e $self->allocation_absolute_path;

    $self->status_message("Writing 'template.sbt' file");
    return unless $self->write_file('template.sbt', 'format_template');

    $self->status_message("Writing 'COMMENT' file");
    return unless $self->write_file(
        'COMMENT', 'format_unstructured_comment');

    my $gas = $self->get_genbank_assembly_submission;
    $self->status_message(
        "Got genbank_assembly_submission gas_id: " 
        . $gas->gas_id
    );

    my $dir_obj = Path::Class::Dir->new($self->allocation_absolute_path);
    while( my $file = $dir_obj->next ) {
        if( not($file->is_dir) && $file->basename =~ /\.agp$/) {
            $self->status_message('Removing previousy existing file '.$file->stringify);
            $file->remove;
        }
    }

    my @gsfs=$gas->get_file_sets;
    foreach my $gsf (@gsfs) {
        $self->status_message('Processing agp_file '.$gsf->agp_file_path.', '.
                              'contig file '.$gsf->contigs_bases_file_path);
        my $agp = GenBank::AGP->new(
                                    agp   => $gsf->agp_file_path,
                                    fasta => $gsf->contigs_bases_file_path,
                                   );
        
        # potentially filtering contigs here
        $self->status_message("entering modify_contigs");
        my $num_contigs_filtered = $self->modify_contigs($agp);
        $self->status_message("exiting modify_contigs");
        $self->status_message("# of contigs filtered: $num_contigs_filtered");

        #TODO remove adjacent gaps
        # I'm skipping this feature for now, because pminx said
        # small contigs will likely have been removed from the
        # contigs file and agp file at this point

        my $strategy = $num_contigs_filtered ? 'complex' : 'simple';
        $self->status_message("strategy: $strategy");

        if ($strategy eq 'complex') {
            # Performance hit, but more robust
            $self->status_message("entering write_agp_fasta_and_cmt_files");
            $self->write_agp_fasta_and_cmt_files($agp);
            $self->status_message("exiting write_agp_fasta_and_cmt_files");
        }
        else {
            # Better performance, but not as robust
            # use when no contigs have been filtered out
            $self->status_message("entering simple_write_agp_fasta_and_cmt_files");
            $self->simple_write_agp_fasta_and_cmt_files($agp);
            $self->status_message("exiting simple_write_agp_fasta_and_cmt_files");
        }
    }

    $self->status_message(
        "setting genbank_assembly_submission status to 'initialized'"
    );
    $gas->status('initialized');
}

sub modify_contigs {
    my $self = shift;
    my ($agp) = @_;

    my $gas = $self->get_genbank_assembly_submission;
    my $size = $gas->minimum_contig_length;

    my $total_contigs = $agp->component_count;
    $self->status_message("Processing through $total_contigs total contigs");

    my $removal_count = 0;
    $self->status_message("Creating iterator");
    my $i = $agp->create_iterator;
    while (my $c = $i->next_component) {
        if ($c->length < $size) {
            $c->remove;
            $removal_count++;
        }

        my ($contig_number) = $c->component_id =~ m/((\d+[\._]){1,2}.*)$/;
        unless($contig_number) {
            $self->error_message("Unable to parse out the contig number from ".$c->component_id." Perhaps you are missing #.#?");
            die "Unable to parse out contig number from ".$c->component_id;
        }
        $self->status_message("Found contig number $contig_number");
        $c->component_id(join '-', $gas->version, $contig_number);
    }

    return $removal_count;
}

sub simple_write_agp_fasta_and_cmt_files {
    my $self  = shift;
    my ($agp) = @_;

    # Forget about using the iterator, which is slow.
    # Just open the original contigs.bases FASTA file and 
    # and process through it record-by-record and partition
    # it up correctly.  We are keeping all the items.

    #Write out the AGP file
    my $gas = $self->get_genbank_assembly_submission;
    my $version = $gas->version;
    my $agp_file = $self->output_agp_file_path($agp->agp);
    $self->status_message("Writing out AGP file: $agp_file");
    $agp->write( $agp_file );

    #Write out the contigs to one or more fasta files

    my $total_contigs = $agp->component_count;
    my $contig_file_size = $agp->fasta->file_path->stat->size;

    # configure contig file partition parameters
    my ($CONTIGS_PER_FILE, $OVERRUN_ALLOWANCE, $should_make_last_file_big) =
      $self->_contig_partition_parameters($total_contigs, $contig_file_size);

    # When should a new file should be opened
    my $should_open_new_file = sub {
        my ($contig_number) = @_;
        return 1 if $contig_number == 0;

        if ($should_make_last_file_big) {
            return 0 if ($total_contigs - $OVERRUN_ALLOWANCE) < 0
        }

        return 1 if 0 == ($contig_number % $CONTIGS_PER_FILE);
        return 0; # default case
    };

    # Calculate number of files to be created (estimated)
    my $estimated_fsa_file_count = ceil($total_contigs/$CONTIGS_PER_FILE);
    $self->status_message("Processing $total_contigs total contigs");
    $self->status_message("Estimated .fsa/.cmt sets: $estimated_fsa_file_count");

    my $contigs_bases = Path::Class::File->new( $agp->fasta->file_path );
    unless ( -e $contigs_bases ) {
        die "[err] Could not find: $contigs_bases on the file system!\n"
    }

    local $/ = '>';

    my $contigs_fh = $contigs_bases->openr;

    # initialize input file
    (undef) = scalar <$contigs_fh>; # skip first "empty" entry;

    # initial output files setup
    my $contig_count = 0;
    my ($cmt_file, $fsa_file, $out_fh);

    while (my $record = <$contigs_fh>) {
        if ( $should_open_new_file->($contig_count) ) {
            if ($out_fh) {
                $out_fh->close
                  or die "[err] Could not close ", $fsa_file->basename, "!\n";
            }
            $cmt_file = $self->generate_cmt_file($self->file_count);
            $fsa_file = $self->generate_fsa_file($self->file_count);
            $out_fh   = $fsa_file->openw;
            $self->increase_file_count;
        }
        chomp($record);
        my ($header, $seq) = split("\n", $record, 2);
        $self->report_fasta_header($header, $version) if $contig_count == 0;
        $header = &maybe_convert_header_structure($header, $version);
        print $out_fh ">$header\n$seq";
        $contig_count++;
    }
}

sub report_fasta_header {
    my ($self, $header, $version) = @_;
    if( $header =~ /^Contig/ ) {
        $self->status_message("Found older/non-chromosonal FASTA header--replacing \'Contig\' with $version");
    } else {
        $self->status_message('Did not find \'Contig\'; must be chromosonal assembly--no FASTA header change');
    }
}

sub maybe_convert_header_structure {
    my ($header, $version) = @_;
    $header =~ s/^Contig(\S+)/$version-$1/;
    return $header;
}

sub generate_cmt_file {
    my ($self, $file_count) = @_;
    my $base_name = "contigs." . sprintf("%02d", $file_count);

    my $cmt_file = $self->allocation_absolute_path->file("$base_name.cmt");

    $self->status_message("Writing file: $cmt_file");
    $self->write_file( "$base_name.cmt", 'format_structured_comment')
        or die "failed to write $base_name.cmt";
    return $cmt_file;
}

sub generate_fsa_file {
    my ($self, $file_count) = @_;
    my $base_name = "contigs." . sprintf("%02d", $file_count);

    my $fsa_file = $self->allocation_absolute_path->file("$base_name.fsa");
    $self->status_message("Creating file: $fsa_file");
    return $fsa_file;
}

sub _contig_partition_parameters {
    my ($self, $total_contigs, $contig_file_size) = @_;

    # If the component count is less than or equal to 2000
    # modulo 10,000, then just stick those extra few components
    # with the previous 10,000.  A last page will never have fewer
    # than 2000 contigs.

    # This is a limitation of the tbl2asn which is a NCBI tool. 
    my $MAX_FILE_SIZE = 2_000_000_000;
    my $MAX_CONTIG_PER_FILE = 20_000; # see LS-7174

    my $NUMBER_OF_FILES = max( ceil($total_contigs / $MAX_CONTIG_PER_FILE), ceil($contig_file_size / $MAX_FILE_SIZE));

    my $CONTIGS_PER_FILE  = ceil($total_contigs / $NUMBER_OF_FILES);
    my $OVERRUN_ALLOWANCE = 0.2*$CONTIGS_PER_FILE;
    my $should_make_last_file_big = (
        $OVERRUN_ALLOWANCE <= ($total_contigs % $CONTIGS_PER_FILE)
    );

    return ($CONTIGS_PER_FILE, $OVERRUN_ALLOWANCE, $should_make_last_file_big);
}

sub write_agp_fasta_and_cmt_files {
    my $self = shift;
    my ($agp) = @_;

    #Write out the AGP file
    my $gas = $self->get_genbank_assembly_submission;
    my $agp_file = $self->output_agp_file_path($agp->agp);
    $self->status_message("Writing out AGP file: $agp_file");
    $agp->write( $agp_file );

    #Write out the contigs to one or more fasta files

    my $total_contigs = $agp->component_count;
    my $contig_file_size = $agp->fasta->file_path->stat->size;

    # configure contig file partition parameters
    my ($CONTIGS_PER_FILE, $OVERRUN_ALLOWANCE, $should_make_last_file_big) =
      $self->_contig_partition_parameters($total_contigs, $contig_file_size);

    # When should a new file should be opened
    my $should_open_new_file = sub {
        my ($contig_number) = @_;
        return 1 if $contig_number == 0;

        if ($should_make_last_file_big) {
            return 0 if ($total_contigs - $OVERRUN_ALLOWANCE) < 0
        }

        return 1 if 0 == ($contig_number % $CONTIGS_PER_FILE);
    };

    # How to open a new file, and how to name it
    my $open_new_file = sub {
        # A weird thing about tbl2asn:
        # If there are structured comments, one .cmt file
        # must exist for each contigs file, and they must
        # be named the same except for the extension (.fsa vs .cmt)

        my $fsa_file = $self->generate_fsa_file($self->file_count);
        my $cmt_file = $self->generate_cmt_file($self->file_count);
        my $fsa_fh = $fsa_file->openw;
        $self->increase_file_count;
        return ($fsa_file, $fsa_fh);
    };

    # Calculate number of files to be created (estimated)
    my $estimated_fsa_file_count = ceil($total_contigs/$CONTIGS_PER_FILE);
    $self->status_message("Processing $total_contigs total contigs");
    $self->status_message("Estimated .fsa/.cmt sets: $estimated_fsa_file_count");

    $self->status_message("Creating iterator");
    my $i = $agp->create_iterator;

    #Loop over contigs, write .fsa and .cmt files
    my $contig_count = 0;
    my ($fsa_file, $fh);
    my $buffer = '';
    $self->status_message("Entering iteration loop");
    while (my $c = $i->next_component) {

        if ( $should_open_new_file->($contig_count) ) {
            # current fsa file cleanup - if already opened
            if ($fh) {  
                # flush out the buffer if necessary
                print($fh $buffer)
                  or die "[err] Could not print to ", $fsa_file->basename, "!\n";
                $buffer = '';

                $self->status_message("Closing file: $fsa_file");
                $fh->close
                  or die "[err] Could not close ", $fsa_file->basename, "!\n";
            }

            # generate a new fsa file and filehandle
            ($fsa_file, $fh) = $open_new_file->() 
        }

        # print only if the buffer is greater than 1MB in size
        if ( $buffer && length($buffer) >= 1_000_000 ) {
            $self->status_message(
                "Printing to " . $fsa_file->basename 
                . " @ contig count: $contig_count -- " 
                . $c->component_id . ' -- ' . length($buffer)
            );
            print($fh $buffer)
              or die "[err] Could not print to ", $fsa_file->basename, " !\n";
            $buffer = '';
        }

        $buffer .= $c->read_fasta_entry;
        $contig_count += 1;
    }

    # print out leftover data
    if ($buffer) {
        print($fh $buffer)
          or die "[err] Could not print to ", $fsa_file->basename, "!\n";
        $buffer = '';
    }
    $fh->close or die "[err] Could not close ", $fsa_file->basename, "!\n";
}

sub copy_file {
    my $self = shift;
    my ($src, $dest) = @_;
    unless (copy($src, $dest)) {
        $self->error_message("copy($src, $dest) failed: $!");
        return;
    }

    return 1;
}

sub write_file {
    my $self = shift;
    my ($file_name, $method_name) = @_;

    my $fh = $self->allocation_absolute_path->file($file_name)->openw;
    unless ($fh->print( $self->$method_name ) ) {
        $self->error_message('problem writing '. $file_name);
        return;
    }

    return 1;
}

sub format_template {
    my $self = shift;
    my $authors = join "\n", map {
        sprintf q|{ name name { last "%s" , first "%s" , initials "%s" } } ,|,
            $_->{last},
            $_->{first},
            $_->{initials};
    } @{ decode_json $self->get_genbank_assembly_submission->authors_json };
    my $my_bioproject_id=$self->get_genbank_assembly_submission->bioproject_id;
    my $my_biosample= $self->get_genbank_assembly_submission->biosample_id;
    my $my_biosample_num = substr($my_biosample, 4)+0; # extract number part after SAMN
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
            num $my_bioproject_id,
            data strs {
                "PRJNA$my_bioproject_id"
            }
        },
        {
            label str "BioSample",
            num $my_biosample_num,
            data strs {
                "$my_biosample"
            }
        }
    }
}

EOF
}

sub format_unstructured_comment {
    my $self = shift;
    return $self->get_genbank_assembly_submission->unstructured_comment;
}

sub format_structured_comment {
    my $self = shift;
    my $gas = $self->get_genbank_assembly_submission;

    my $c = '';
    my $add = sub {
        my ($name, $value) = @_;
        die unless defined $name;
        die "missing value for $name" unless defined $value;
        $c .= join("\t", $name, $value) . "\n";
    };

    $add->( 'StructuredCommentPrefix','##Genome-Assembly-Data-START##');
    $add->( 'Assembly Name',          $gas->version);
    $add->( 'Assembly Method',        $gas->assembly_method);
    $add->( 'Genome Coverage',        $gas->genome_coverage .'x');
    $add->( 'Sequencing Technology',  $gas->sequencing_technology);
    $add->( 'StructuredCommentSuffix','##Genome-Assembly-Data-END##');

    return $c;
}

sub expunge_execution {
    my $self = shift;
    my $alloc = $self->get_allocate_disk_space_pse;
    if ($alloc) {
        $self->status_message('Scheduling delete_allocation_data');
        my $del = $alloc->delete_allocation_data;
        unless ($del) {
            $self->error_message('failed to schedule delete_allocation_data');
            $self->pse_status('failed');
            return;
        }

#        $self->status_message('Place deallocate in wait');
#        my $dealloc = $alloc->deallocate;
#        unless ($dealloc) {
#            $self->error_message('failed to schedule deallocate');
#            $self->pse_status('failed');
#            return;
#        }
#        $dealloc->pse_status('wait');
    }
    else {
        $self->status_message('No allocation to remove');
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__END__

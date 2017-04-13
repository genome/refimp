package GSC::PSE::ExecuteTbl2asn;
use Moose;
use GSCApp;
use warnings FATAL => qw(all);
use Path::Class qw(file);

sub root_dir_path { shift->get_prior_pse->allocation_absolute_path }
sub results_dir_path { shift->root_dir_path->subdir('RESULTS') }
sub discrepancy_report_path {
    shift->results_dir_path->file('discrepancy_report') }

sub template_file_path  { shift->root_dir_path->file('template.sbt') }
sub  comment_file_path  { shift->root_dir_path->file('COMMENT') }

sub get_genbank_assembly_submission {
    shift->get_first_prior_pse_with_process_to(
        'configure assembly submission to genbank')
            ->get_genbank_assembly_submission
}

sub confirm {
    my $self = shift;
    return unless $self->SUPER::confirm;

    $self->results_dir_path->mkpath unless -e $self->results_dir_path;

    my $tbl2asn_cmd = $self->tbl2asn_command;
    $self->results_dir_path->file('tbl2asn_command')->openw->say($tbl2asn_cmd);
    $self->_run($tbl2asn_cmd);

    $self->create_tar_file;

    $self->get_genbank_assembly_submission->status('submission created');
    return 1;
}

sub create_tar_file {
    my $self = shift;
    my $gas = $self->get_genbank_assembly_submission;

    # The tar file cannot be created in one step,
    # so it is broken into two steps:
    #   i) Create a tar file with just the agp in it
    #  ii) Append to the tar file with the .sqn files


    my $root_dir_path      = $self->root_dir_path;
    my $results_dir_path   = $self->results_dir_path;
    my $tar_file_path      = $self->results_dir_path->file($gas->version .'.tar');
    my @agp_file_basenames = map { $_->basename } map { $self->get_prior_pse->output_agp_file_path(file($_->agp_file_path)) } $gas->get_file_sets;

    my @sqn_file_names = map {file($_)->basename} glob( $self->results_dir_path->file('*.sqn') );
    die "Expected at least one .sqn file from tbl2asn, "
        ."but none were found in $results_dir_path"
        unless @sqn_file_names;

    local $" = q| |; #ensure @sqn_file_names and agp_file_basenames print with a space between each file name
    $self->_run("tar --create --directory $root_dir_path    --file $tar_file_path @agp_file_basenames");
    $self->_run("tar --append --directory $results_dir_path --file $tar_file_path @sqn_file_names");

    return 1;
}

sub tbl2asn_command {
    my $self = shift;

    my $cmd = 'tbl2asn'
        # Path to Files [String]  Optional
        .' -p '. $self->root_dir_path

        # Path for Results [String]  Optional
        .' -r '. $self->results_dir_path

        # Template File [File In]  Optional
        .' -t '. $self->template_file_path

        # Read FASTAs as Set [T/F]  Optional
        .' -s'

        # Verification: (combine any of the following letters)
        # v Validate with Normal Stringency
        # r Validate without Country Check
        # c BarCode Validation
        # b Generate GenBank Flatfile
        # g Generate Gene Report
        .' -V vb'

        # Discrepancy Report Output File [File Out]  Optional
        .' -Z '. $self->discrepancy_report_path

        # Extra Flags (combine any of the following letters)
        # A Automatic definition line generator
        # C Apply comments in .cmt files to all sequences
        # E Treat like eukaryota in the Discrepancy Report
        .' -X AC'

        # Source Qualifiers [String]  Optional
        ." -j '". $self->source_qualifiers ."'"
    ;

    if (-e $self->comment_file_path) {
        # Comment File [File In]  Optional
        $cmd .= ' -Y '. $self->comment_file_path;
    }

    return $cmd;
}

sub source_qualifiers {
    my $self = shift;
    #format: [modifier=text] [modifier=text] [modifier=text]
    my $configure_pse = $self->get_first_prior_pse_with_process_to(
        "configure assembly submission to genbank");
    my $gas = $configure_pse->get_genbank_assembly_submission;
    my ($name, $strain) = $gas->organism_name_and_strain;
    my $tbl2asn_source_qualifiers   = $gas->tbl2asn_source_qualifiers;

    my $source_qualifiers = qq|[organism=$name]|;
    $source_qualifiers   .= qq| [strain=$strain]| if defined $strain;
    $source_qualifiers   .= qq| [tech=wgs]|;
    $source_qualifiers   .= qq| $tbl2asn_source_qualifiers| if defined $tbl2asn_source_qualifiers;

    return $source_qualifiers;
}

#
# Nothing to do for expunge
sub expunge_execution { 1 }

__PACKAGE__->meta->make_immutable;

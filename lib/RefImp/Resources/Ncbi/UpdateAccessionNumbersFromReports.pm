package RefImp::Resources::Ncbi::UpdateAccessionNumbersFromReports;

use strict;
use warnings;

use Cwd 'cwd';
use File::Temp 'tempdir';
use List::MoreUtils 'firstval';
use RefImp::Resources::Ncbi::ParseAc4htgsReport;
use RefImp::Resources::NcbiFtp;

class RefImp::Resources::Ncbi::UpdateAccessionNumbersFromReports {
    is => 'Command::V2',
    doc => 'update project accesssion number form ncbi reports',
};

sub execute {
    my $self = shift;
    $self->status_message('Update accession numbers from NCBI...');

    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $ftp->cwd('REPORT');

    my $cwd = cwd();
    my $working_dir = tempdir(CLEANUP => 1);
    print "$working_dir\n";
    chdir $working_dir;

    for my $file ( grep { m/fa2htgs.asn.ac4htgs$/ } $ftp->ls ) {

        $ftp->get($file);
        my $report = RefImp::Resources::Ncbi::ParseAc4htgsReport->parse($file);

        $report->{project} = RefImp::Project->get(name => $report->{localseqname});
        $self->fatal_message('No project for %s', $report->{localseqname}) if not $report->{project};

        my @gb_accessions = RefImp::Project::GbAccession->get(
            project_id => $report->{project}->id,
        );
        my $gb_accession = firstval { $_->id eq $report->{accession} } @gb_accessions; # already added
        if ( $gb_accession ) {
            $self->_increment_rank_for_gb_accessions([ grep { $_->id ne $gb_accession->id } @gb_accessions ]);
            $gb_accession->rank(1);
            $gb_accession->version( $report->{version} );
        }
        else {
            $self->_increment_rank_for_gb_accessions(\@gb_accessions) if @gb_accessions;
            $self->_add_gb_accession($report);
        }
        $self->status_message("Project %s has accession %s", $report->{project}->__display_name__, $report->{accession});
    }

    chdir $cwd;
    $self->status_message('Update accession numbers from NCBI...OK');
    return 1;
}

sub _increment_rank_for_gb_accessions {
    my ($self, $gb_accessions) = @_;

    my $rank = 1;
    for my $gb_accession ( sort { $a->rank <=> $b->rank } @$gb_accessions ) {
        $gb_accession->rank( ++$rank );
    }

    return 1;
}

sub _add_gb_accession {
    my ($self, $report) = @_;

    my $gb_accession = RefImp::Project::GbAccession->get($report->{accession});
    next if $gb_accession;
    $gb_accession = RefImp::Project::GbAccession->create(
        id => $report->{accession},
        version => $report->{version},
        project_id => $report->{project}->id,
        rank => 1,
        center => $report->{source},
    );
    $self->fatal_message('Failed to create GB Accession for %s', $report->{accession}) if not $gb_accession;

    return $gb_accession;
}

1;


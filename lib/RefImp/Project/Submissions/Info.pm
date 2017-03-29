package RefImp::Project::Submissions::Info;

use strict;
use warnings;

use IO::File;
use Params::Validate ':types';
use List::Util;
use RefImp::Ace::Directory;
use RefImp::Ace::Reader;
use RefImp::Ace::Sequence;
use YAML;

sub load {
    my ($class, $file) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    die 'Submit info file does not exist! '.$file if not -s $file;
    my $hash = YAML::LoadFile($file);
    die 'Failed to load hash from file! '.$file if not $hash;
    return $hash;
}

sub generate {
    my ($class, $project) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Project'});

    my $self = bless {project => $project}, $class;

    my $submit = {
        TOGGLES =>[],
        COMMENTS =>{},
        GENINFO =>{},
    };

    $self->set_geninfo($submit, $project);

    my $acedir = RefImp::Ace::Directory->create(project => $project);
    my $ace0_file = $acedir->ace0_file;
    die "No ace.0 for ".$project->name if not $ace0_file;

    my $fh = IO::File->new($ace0_file, 'r');
    die "$!\nFailed to open ace file: $ace0_file" if not $fh;

    my $reader = RefImp::Ace::Reader->new($fh);
    die "Failed to create ace reader: $ace0_file" if not $reader;

    my @contig_tags;
    while ( my $obj = $reader->next_object ) {
        if ( $obj->{type} eq 'contig' ) {
            $self->_add_contig_tags($submit, \@contig_tags); # from previous contig
            @contig_tags = ();
            $self->_add_contig($obj);
        }
        elsif ( $obj->{type} eq 'contig_tag' ) {
            push @contig_tags, $obj;
        }
    }
    $self->_add_contig_tags($submit, \@contig_tags); # from last contig

    $self->resolve_contig_data($submit);

    return $submit;
}

sub set_geninfo {
    my ($self, $submit, $project) = @_;

    my $notes_file = $project->notes_file;
    my $taxonomy = $project->taxonomy;
    $submit->{GENINFO}->{CloneName} = $project->name;
    $submit->{GENINFO}->{Organism} = $taxonomy->common_name;
    $submit->{GENINFO}->{Chromosome} = $taxonomy->chromosome;
    $submit->{GENINFO}->{PrefinisherUserList} = [ $notes_file->prefinishers ];
    $submit->{GENINFO}->{FinisherUserList} = [ $notes_file->finishers ];
    $submit->{GENINFO}->{FinishingGroup} = 'avery',
    $submit->{GENINFO}->{ProductionGroup} = 'WUGSC';
    $submit->{GENINFO}->{DigestAssemblyConfirmedByCombo} = 'consed';

    # Accession and overlaps info is probably not updated for a lot of project
    my @submissions =  $project->submissions;
    my $submission = List::Util::first { $_->phase eq '3' } @submissions;
    $submit->{GENINFO}->{CloneAccession} = ( $submission ) ? $submission->accession_id : undef;

    return 1;
}

sub set_contig_data {
    my ($self, $submit, $tag) = @_;

    my $contig_num = $tag->{contig_name};
    $contig_num =~ s/Contig//;

    my $ctg_info;
    if (exists $submit->{COMMENTS}->{ContigData}
            and grep { $_->{ContigNumber} eq $contig_num } @{ $submit->{COMMENTS}->{ContigData} })
    {
        ($ctg_info) = grep { $_->{ContigNumber} eq $contig_num } @{ $submit->{COMMENTS}->{ContigData} };
    }
    else
    {
        $ctg_info->{ContigNumber} = $contig_num;
        $ctg_info->{ContigFinishedFrom} = 1;
        $ctg_info->{StartCloneSite} = 1;
        $ctg_info->{EntireContigGoesFrom} = 1;
        $ctg_info->{ContigFinishedTo} = $self->contig_seq( $tag->{contig_name} )->bases_uppadded_length;
        $ctg_info->{EndCloneSite} = $self->contig_seq( $tag->{contig_name} )->bases_uppadded_length;
        $ctg_info->{EntireContigGoesTo} = $self->contig_seq( $tag->{contig_name} )->bases_uppadded_length;
        push @{ $submit->{COMMENTS}->{ContigData} }, $ctg_info;
    }

    if ($tag->{data} =~ /start/i)
    {
        if ($tag->{data} =~ /clone\s+site/)
        {
            $ctg_info->{StartCloneSite} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
        }
        elsif ($tag->{data} =~ /finished\s+region/)
        {
            $ctg_info->{ContigFinishedFrom} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
        }
    }
    else
    {
        if ($tag->{data} =~ /clone\s+site/)
        {
            $ctg_info->{EndCloneSite} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});
        }
        elsif ($tag->{data} =~ /finished\s+region/)
        {
            $ctg_info->{ContigFinishedTo} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});
        }
    }

    return;
}

sub resolve_contig_data
{
    my ($self, $submit) = @_;

    return unless exists $submit->{COMMENTS}->{ContigData};
    return unless ref $submit->{COMMENTS}->{ContigData} eq 'ARRAY';
    return if scalar @{ $submit->{COMMENTS}->{ContigData} } > 1;

    my $ctg_data = @{ $submit->{COMMENTS}->{ContigData} }[0];

    foreach my $key ( keys %$ctg_data )
    {
        $submit->{GENINFO}->{$key} = $ctg_data->{$key};
    }

    return;
}

sub set_contig_data_for_dofinish
{
    my ($self, $submit, $tag) = @_;

    my $contig_num = $tag->{contig_name};
    $contig_num =~ s/Contig//;

    my $info;
    $info->{doFinishCommentsContigNumber} = $contig_num;
    $info->{doFinishCommentsStartBP} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
    $info->{doFinishCommentsEndBP} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});

    push @{ $submit->{COMMENTS}->{doFinishComments} }, $info;

    return;
}

sub add_toggle
{
    my ($self, $submit, $type) = @_;

    push @{$submit->{TOGGLES}}, $type . "Toggle";

    return;
}

sub contig_seq {
    my ($self, $contig_name) = @_;
    $self->{_contig_seqs}->{$contig_name};
}

sub _add_contig {
    my ($self, $contig) = @_;
    my $sequence = RefImp::Ace::Sequence->new(bases => $contig->{consensus});
    $self->{_contig_seqs}->{ $contig->{name} } = $sequence;
}

sub _add_contig_tags {
    my ($self, $submit, $contig_tags) = @_;

    for my $tag ( sort { $a->{start_pos} <=> $b->{start_pos} } @$contig_tags ) {
        $self->_add_tag($submit, $tag);
    }

    return 1;
}

sub _add_tag {
    my ($self, $submit, $tag) = @_;

    return unless $tag->{tag_type} =~ /annotation/i
        or $tag->{tag_type} =~ /singlesubclone/i
        or $tag->{tag_type} =~ /dofinish/i;

    my $temp = {};
    # Start/End
    if ($tag->{data} =~ /^comment\{\nstart/i or $tag->{data} =~ /^comment\{\nend/i) {
        $self->set_contig_data($submit, $tag);
    }
    # doFinish
    elsif ($tag->{tag_type} =~ /dofinish/i) {
        $self->set_contig_data_for_dofinish($submit, $tag);
    }
    # Digest Comments
    elsif ($tag->{data} =~ /digest\s+comments/i) {
        my $type = 'DigestComments';

        my $comment = $tag->{data};
        $comment =~ s/^COMMENT\{\n\s*digest\s+comments\s*\n//;
        $comment =~ s/\C\}$//;

        $submit->{GENINFO}->{$type . 'Toggle'} = 1;
        $submit->{GENINFO}->{$type . 'Text'} = $comment;
    }
    # Other Comments
    elsif ($tag->{data} =~ /other\s+comments/i) {
        my $type = 'AnyOtherComments';

        $self->add_toggle($submit, $type);
        $self->set_comment($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{AnyOtherComments}}, $temp;
    }
    # PCR Only
    elsif ($tag->{data} =~ /pcr\s+only|pcr_only/i) {
        my $type = 'PCROnlyRegionsComments';

        $self->add_toggle($submit, $type);
        $self->set_from_and_to($temp, $tag, $type);
        $self->set_contig_num($temp, $tag, $type);

        $temp->{PCROnlyRegionsCommentsDNASource} = ($tag->{data} =~ /genomic/) ? 'genomic dna': 'project dna';

        push @{$submit->{COMMENTS}->{PCROnlyRegionsComments}}, $temp;
    }
    # Stolen Data Only
    elsif ( $tag->{data} =~ /stolen\s+data/i ) {
        my $type = 'OtherClonesComments';
        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);
        $self->set_contig_num($temp, $tag, $type);
        my @comments = split ("\n", $tag->{data});
        for my $comment_string ( @comments ) {
            if ( $comment_string =~ /stolen\s+from:/i ) {
                my $comment = "$'";
                $comment =~ s/^\s+//;
                $temp->{OtherClonesCommentsStolenFromComment} = $comment if $comment;
            }
            if ( $comment_string =~ /data\s+type:/i ) {
                my $comment = "$'";
                $comment =~ s/^\s+//;
                $temp->{OtherClonesCommentsDataTypeComment} = $comment if $comment;
            }
        }

        push @{$submit->{COMMENTS}->{OtherClonesComments} }, $temp;
    }
    # Single Subclone
    elsif ($tag->{tag_type} eq "SingleSubclone" or $tag->{data} =~ /singlesubclone/i or $tag->{data} =~ /single\s+subclone/i) {
        my $type = 'SingleCloneCoverageComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        $temp->{SingleCloneCoverageSubcloneType} = ($tag->{data} =~ /(m13)/i)
        ? ucfirst ($1)
        : 'Plasmid';

        push @{$submit->{COMMENTS}->{SingleCloneCoverageComments}}, $temp;
    }
    # Unr Tandem
    elsif($tag->{data} =~ /unr\s+tandem/i) {
        my $type = 'UnresolvedTandemRepeatsComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);
        $self->set_sizing_info($temp, $tag, $type);
        $self->set_fin_standards($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{UnresolvedTandemRepeatsComments}}, $temp;
    }
    # Unr SSR
    elsif($tag->{data} =~ /unr\s+ssr/i) {
        my $type = 'UnresolvedDiTriRepeatsComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);
        $self->set_sizing_info($temp, $tag, $type);
        $self->set_fin_standards($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{UnresolvedDiTriRepeatsComments}}, $temp;
    }
    # Unr Mono
    elsif($tag->{data} =~ /unresolved\s+mono/i or $tag->{data} =~ /unr\s+mono/i) {
        my $type = 'HomopolymericRunComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{HomopolymericRunComments}}, $temp;
    }
    # Unr Duplication
    elsif($tag->{data} =~ /unr\s+duplication/i) {
        my $type = 'UnresolvedLargeDuplicationsComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);
        $self->set_sizing_info($temp, $tag, $type);
        $self->set_discrepancy($temp, $tag, $type);
        $self->set_fin_standards($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{UnresolvedLargeDuplicationsComments}}, $temp;
    }
    # Unr Inverted
    elsif($tag->{data} =~ /unr\s+inverted/i) {
        my $type = 'UnresolvedInvertedRepeatsComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);
        $self->set_sizing_info($temp, $tag, $type);
        $self->set_discrepancy($temp, $tag, $type);
        $self->set_fin_standards($temp, $tag, $type);
        $self->set_orientation($temp, $tag, $type);


        push @{$submit->{COMMENTS}->{UnresolvedInvertedRepeatsComments}}, $temp;

    }
    # Mini lib - Shatter and Tbomb
    elsif($tag->{data} =~ /shatter/i or $tag->{data} =~ /tbomb/i or $tag->{data} =~ /transposon\s+bomb/i) {
        my $type = 'MiniLibComments';

        $self->add_toggle($submit, $type);
        $self->set_contig_num($temp, $tag, $type);
        $self->set_from_and_to($temp, $tag, $type);
        $self->set_plate_info($temp, $tag, $type);

        $temp->{MiniLibCommentsCloneContains} = ($tag->{data} =~ /shatter/i)
        ? 'Shattered Library'
        : 'Transposon Bombing';

        push @{$submit->{COMMENTS}->{MiniLibComments}}, $temp;
    }
    # Ambiguous
    elsif($tag->{data} =~ /ambiguous\s+base/i) {
        my $type = 'UnsureBasecallComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{UnsureBasecallComments}}, $temp;
    }
    # Coor Approval
    elsif ($tag->{data} =~ /coordinator\s+approval/i) {
        my $type = 'NonGenbankComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        $tag->{data} =~ /^(.*)/;
        my $coordinator = $1;
        $temp->{NonGenbankCommentsCoordinators} = $coordinator;

        push @{$submit->{COMMENTS}->{NonGenbankComments}}, $temp;
    }
    # Assembly Piece
    elsif ($tag->{data} =~ /assembly\s+piece/i) {
        my $type = 'AssemblyPiecesComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{AssemblyPiecesComments}}, $temp;
    }
    # Transposon
    elsif
    ($tag->{data} =~ /transposon\s+in\s+finished\s+region/i
            or $tag->{data} =~ /transposon\s+excised\s+from\s+finished\s+region/i
            or $tag->{data} =~ /transposon\s+in\s+vector/i)
    {
        my $type = 'TransposonComments';

        $self->add_toggle($submit, $type);
        $self->set_contig_num($temp, $tag, $type);
        $self->set_transposon_comment($temp, $tag, $type);

        if ($tag->{data} =~ /excised/i)
        {
            $self->set_excised_transposon($temp, $tag);
            $temp->{TransposonCommentsSequenceRegion} = 'Finished Region';
        }
        elsif ($tag->{data} =~ /vector/i)
        {
            $temp->{TransposonCommentsSequenceRegion} = 'Vector';

        }
        else
        {
            $self->set_finished_region_transposon($temp, $tag);
            $temp->{TransposonCommentsSequenceRegion} = 'Finished Region';

        }

        push @{$submit->{COMMENTS}->{TransposonComments}}, $temp;
    }
    elsif ( $tag->{data} =~ /non\-repetitive\s+but\s+unresolved\s+region/ )
    {
        my $type = 'NonRepetitiveButUnresolvedRegionComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{NonRepetitiveButUnresolvedRegionComments}}, $temp;
    }
    elsif ( $tag->{data} =~ /GSS\s+and\/or\s+mRNA\s+only\s+data/ )
    {
        my $type = 'GSSAndOrMRNAOnlyDataComments';

        $self->add_toggle($submit, $type);
        $self->set_start_and_end($temp, $tag, $type);

        push @{$submit->{COMMENTS}->{GSSAndOrMRNAOnlyDataComments}}, $temp;
    }
}

sub get_base_for_padded_position
{
    my ($self, $contig_name, $padded_pos) = @_;

    return $self->contig_seq($contig_name)->get_padded_base_value( $padded_pos - 1 );
}

sub get_unpadded_pos
{
    my ($self, $contig_name, $padded_pos) = @_;

    return $self->contig_seq($contig_name)->unpadded_for_padded_position($padded_pos);
}

sub set_start_and_end
{
    my ($self, $temp, $tag, $type) = @_;

    $temp->{ $type.'StartBP' } = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
    $temp->{ $type.'EndBP' } = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});

    return;
}

sub set_from_and_to
{
    my ($self, $temp, $tag, $type) = @_;

    $temp->{ $type . 'RegionFrom' } = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
    $temp->{ $type . 'RegionTo' } = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});

    return;
}
sub set_contig_num
{
    my ($self, $temp, $tag, $type) = @_;

    my $contig_name = $tag->{contig_name};
    $contig_name =~ s/Contig//;

    $temp->{ $type . 'ContigNumber' } = $contig_name;

    return;
}

sub set_comment
{
    my ($self, $temp, $tag, $type) = @_;

    my $comment = $tag->{data};
    $comment =~ s/^COMMENT\{\n//;
    $comment =~ s/\C\}$//;

    $temp->{ $type . 'Text' } = $comment;

    return;
}

sub set_transposon_comment
{
    my ($self, $temp, $tag, $type) = @_;

    my $comment = $tag->{data};
    $comment =~ s/^COMMENT\{\n//;
    $comment =~ s/\C\}$//;

    $temp->{$type.'TextComment'} = $comment;
    $temp->{$type.'TextCommentToggle'} = 1;

    return;
}

sub set_orientation
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->{data} =~ /meets finishing standards:\s*(.*)\n/;
    my $orientation = $1;

    $temp->{$type.'OrientationCheckbox'} = ( defined $orientation && $orientation =~ /n/i) ? 1 : 0;

    return;
}

sub set_fin_standards
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->{data} =~ /meets finishing standards:\s*(.*)\n/;
    my $fin_standards = $1 || '';

    $temp->{$type.'DoesNotMeetFinishingStandardsCheckbox'} = ($fin_standards =~ /n/i) ? 1 : 0;

    return;
}


sub set_discrepancy
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->{data} =~ /discrepancies:\s*(.*)\n/;
    my $discrepancy = $1;

    $temp->{$type.'DiscrepanciesCheckbox'} = ( defined $discrepancy && $discrepancy =~ /y/i) ? 1 : 0;

    return;
}

sub set_sizing_info
{
    my ($self, $temp, $tag, $type) = @_;

    my ($sizing) = $tag->{data} =~ /sizing:\s*(digest|subclone|pcr|too large to size)\s*\n/i;
    my ($subclone) = $tag->{data} =~ /subclone:\s*(.*)\n/;
    my ($real) = $tag->{data} =~ /real\/product_size:\s*(.*)\n/;
    my ($insilico) = $tag->{data} =~ /insilico:\s*(.*)\n/;
    my ($lib_size) = $tag->{data} =~ /library_size:\s*(.*)\n/;


    $temp->{$type.'SizingInfo'} = $sizing;

    $type =~ s/Comments//;

    if (defined $sizing and $sizing =~ /digest/i)
    {
        my ($enzyme) = $tag->{data} =~ /enzyme:\s*(\w*)\s*\n/;

        $temp->{$type.'Enzyme'} = $enzyme;
        $temp->{$type.'InSilico'} = $insilico;
        $temp->{$type.'Real'} = $real; 
    }
    elsif (defined $sizing and $sizing =~ /pcr/i)
    {
        $temp->{$type.'AssemblySize'} = $insilico; 
        $temp->{$type.'ProductSize'} = $real; 
    }
    elsif (defined $sizing and $sizing =~ /subclone/i)
    {
        $temp->{$type.'SubClone'} = $subclone;
        $temp->{$type.'InSilico'} = $insilico;
        $temp->{$type.'LibrarySize'} = $lib_size;
    }

    return;
}

sub set_plate_info
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->{data} =~ /DNA source:\s*(.*)\n/;
    $temp->{$type.'DNASource'} = $1;
    $tag->{data} =~ /Plate name:\s*(.*)\n/;
    $temp->{$type.'PlateName'} = $1;
    $tag->{data} =~ /Plasmid\/pcr name:\s*(.*)\n/;
    $temp->{$type.'TextComment'} = $1;
    $temp->{$type.'TextCommentToggle'} = 1;

    return;
}

sub set_finished_region_transposon
{
    my ($self, $temp, $tag) = @_;

    $temp->{TransposonCommentsSequenceRegion} = 'Finished Region';

    # Ugly
    $temp->{TransposonCommentsLastBaseBefore} = $self->get_base_for_padded_position($tag->{contig_name}, $tag->{start_pos} - 1);
    $temp->{TransposonCommentsLastBaseBeforePosition} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos} - 1);
    $temp->{TransposonCommentsFirstBaseOf} = $self->get_base_for_padded_position($tag->{contig_name}, $tag->{start_pos});
    $temp->{TransposonCommentsFirstBaseOfPosition} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
    $temp->{TransposonCommentsLastBaseOf} = $self->get_base_for_padded_position($tag->{contig_name}, $tag->{end_pos});
    $temp->{TransposonCommentsLastBaseOfPosition} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});
    $temp->{TransposonCommentsFirstBaseAfter} = $self->get_base_for_padded_position($tag->{contig_name}, $tag->{end_pos} + 1);
    $temp->{TransposonCommentsFirstBaseAfterPosition} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos} + 1);

    return;
}

sub set_excised_transposon
{
    my ($self, $temp, $tag) = @_;

    # More Ugly
    $temp->{TransposonCommentsLastBaseBefore} = $self->get_base_for_padded_position($tag->{contig_name}, $tag->{start_pos});
    $temp->{TransposonCommentsLastBaseBeforePosition} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{start_pos});
    $temp->{TransposonCommentsFirstBaseOf} = 'N';
    $temp->{TransposonCommentsFirstBaseOfPosition} = 'NA';
    $temp->{TransposonCommentsLastBaseOf} = 'N';
    $temp->{TransposonCommentsLastBaseOfPosition} = 'NA';
    $temp->{TransposonCommentsFirstBaseAfter} = $self->get_base_for_padded_position($tag->{contig_name}, $tag->{end_pos});
    $temp->{TransposonCommentsFirstBaseAfterPosition} = $self->get_unpadded_pos($tag->{contig_name}, $tag->{end_pos});

    return;
}

1;


package RefImp::Clone::Submissions::Info;

use strict;
use warnings;

use GSC::IO::Assembly::Ace;
use Params::Validate ':types';
use RefImp::Project::Command::Overlaps;
use YAML;

sub load {
    my ($class, $file) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    die 'Submit info file does not exist! '.$file if not -s $file;
    my $hash = YAML::LoadFile($file);
    die 'Failed to load hash from file! '.$file if not $hash;
    return $hash;
}

sub generate {
    my ($class, $clone) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Clone'});

    my $self = bless {clone => $clone}, $class;

    my $submit = {
        TOGGLES =>[],
        COMMENTS =>{},
        GENINFO =>{},
    };

    $self->set_geninfo($submit, $clone);

    # TODO move/copy this to RefImp and only load what is needed
    my $ace0_path = $clone->ace0_path;
    die "No ace.0 for ".$clone->name if not $ace0_path;
    my $ao = GSC::IO::Assembly::Ace->new(input_file => $ace0_path);
    die 'Failed to load ace 0!' if not $ao;

    foreach my $contig_name (@{  $ao->get_contig_names })
    {
        my $contig = $ao->get_contig($contig_name);
        $self->contig_seq($contig_name, $contig->sequence);

        foreach my $tag (sort {$a->start <=> $b->start} @{ $contig->tags })
        {
            next unless $tag->type =~ /annotation/i
                or $tag->type =~ /singlesubclone/i
                or $tag->type =~ /dofinish/i;

            $tag->text('') unless $tag->text;

            my $temp = {};

            # Start/End
            if ($tag->text =~ /^comment\{\nstart/i
                    or $tag->text =~ /^comment\{\nend/i)
            {
                $self->set_contig_data($submit, $tag);
            }
            # doFinish
            elsif ($tag->type =~ /dofinish/i)
            {
                $self->set_contig_data_for_dofinish($submit, $tag);
            }
            # Digest Comments
            elsif ($tag->text =~ /digest\s+comments/i)
            {
                my $type = 'DigestComments';

                my $comment = $tag->text;
                $comment =~ s/^COMMENT\{\n\s*digest\s+comments\s*\n//;
                $comment =~ s/\C\}$//;

                $submit->{GENINFO}->{$type . 'Toggle'} = 1;
                $submit->{GENINFO}->{$type . 'Text'} = $comment;
            } 
            # Other Comments
            elsif ($tag->text =~ /other\s+comments/i)
            {
                my $type = 'AnyOtherComments';

                $self->add_toggle($submit, $type);
                $self->set_comment($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{AnyOtherComments}}, $temp;
            }
            # PCR Only
            elsif ($tag->text =~ /pcr\s+only|pcr_only/i)
            {
                my $type = 'PCROnlyRegionsComments';

                $self->add_toggle($submit, $type);
                $self->set_from_and_to($temp, $tag, $type);
                $self->set_contig_num($temp, $tag, $type);

                $temp->{PCROnlyRegionsCommentsDNASource} = ($tag->text =~ /genomic/) ? 'genomic dna': 'project dna';

                push @{$submit->{COMMENTS}->{PCROnlyRegionsComments}}, $temp;
            }
            # Stolen Data Only
            elsif ( $tag->text =~ /stolen\s+data/i ) {
                my $type = 'OtherClonesComments';
                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);
                $self->set_contig_num($temp, $tag, $type);
                my @comments = split ("\n", $tag->text);
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
            elsif ($tag->type eq "SingleSubclone" or $tag->text =~ /singlesubclone/i or $tag->text =~ /single\s+subclone/i)
            {
                my $type = 'SingleCloneCoverageComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                $temp->{SingleCloneCoverageSubcloneType} = ($tag->text =~ /(m13)/i)
                ? ucfirst ($1)
                : 'Plasmid';

                push @{$submit->{COMMENTS}->{SingleCloneCoverageComments}}, $temp;
            }
            # Unr Tandem
            elsif($tag->text =~ /unr\s+tandem/i)
            {
                my $type = 'UnresolvedTandemRepeatsComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);
                $self->set_sizing_info($temp, $tag, $type);
                $self->set_fin_standards($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{UnresolvedTandemRepeatsComments}}, $temp;
            }
            # Unr SSR
            elsif($tag->text =~ /unr\s+ssr/i)
            {
                my $type = 'UnresolvedDiTriRepeatsComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);
                $self->set_sizing_info($temp, $tag, $type);
                $self->set_fin_standards($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{UnresolvedDiTriRepeatsComments}}, $temp;
            }
            # Unr Mono
            elsif($tag->text =~ /unresolved\s+mono/i or $tag->text =~ /unr\s+mono/i)
            {
                my $type = 'HomopolymericRunComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{HomopolymericRunComments}}, $temp;
            }
            # Unr Duplication
            elsif($tag->text =~ /unr\s+duplication/i)
            {
                my $type = 'UnresolvedLargeDuplicationsComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);
                $self->set_sizing_info($temp, $tag, $type);
                $self->set_discrepancy($temp, $tag, $type);
                $self->set_fin_standards($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{UnresolvedLargeDuplicationsComments}}, $temp;
            }
            # Unr Inverted
            elsif($tag->text =~ /unr\s+inverted/i)
            {
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
            elsif($tag->text =~ /shatter/i or $tag->text =~ /tbomb/i or $tag->text =~ /transposon\s+bomb/i)
            {
                my $type = 'MiniLibComments';

                $self->add_toggle($submit, $type);
                $self->set_contig_num($temp, $tag, $type);
                $self->set_from_and_to($temp, $tag, $type);
                $self->set_plate_info($temp, $tag, $type);

                $temp->{MiniLibCommentsCloneContains} = ($tag->text =~ /shatter/i)
                ? 'Shattered Library' 
                : 'Transposon Bombing';

                push @{$submit->{COMMENTS}->{MiniLibComments}}, $temp;
            }
            # Ambiguous
            elsif($tag->text =~ /ambiguous\s+base/i)
            {
                my $type = 'UnsureBasecallComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{UnsureBasecallComments}}, $temp;
            }
            # Coor Approval
            elsif ($tag->text =~ /coordinator\s+approval/i)
            {
                my $type = 'NonGenbankComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                $tag->text =~ /^(.*)/;
                my $coordinator = $1;
                $temp->{NonGenbankCommentsCoordinators} = $coordinator;

                push @{$submit->{COMMENTS}->{NonGenbankComments}}, $temp;
            }
            # Assembly Piece
            elsif ($tag->text =~ /assembly\s+piece/i)
            {
                my $type = 'AssemblyPiecesComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{AssemblyPiecesComments}}, $temp;
            }
            # Transposon
            elsif
            ($tag->text =~ /transposon\s+in\s+finished\s+region/i
                    or $tag->text =~ /transposon\s+excised\s+from\s+finished\s+region/i
                    or $tag->text =~ /transposon\s+in\s+vector/i)
            {
                my $type = 'TransposonComments';

                $self->add_toggle($submit, $type);
                $self->set_contig_num($temp, $tag, $type);
                $self->set_transposon_comment($temp, $tag, $type);

                if ($tag->text =~ /excised/i)
                {
                    $self->set_excised_transposon($temp, $tag);
                    $temp->{TransposonCommentsSequenceRegion} = 'Finished Region';
                }
                elsif ($tag->text =~ /vector/i)
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
            elsif ( $tag->text =~ /non\-repetitive\s+but\s+unresolved\s+region/ )
            {
                my $type = 'NonRepetitiveButUnresolvedRegionComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{NonRepetitiveButUnresolvedRegionComments}}, $temp;
            }
            elsif ( $tag->text =~ /GSS\s+and\/or\s+mRNA\s+only\s+data/ )
            {
                my $type = 'GSSAndOrMRNAOnlyDataComments';

                $self->add_toggle($submit, $type);
                $self->set_start_and_end($temp, $tag, $type);

                push @{$submit->{COMMENTS}->{GSSAndOrMRNAOnlyDataComments}}, $temp;
            }

        }
    }

    $self->resolve_contig_data($submit);

    return $submit;
}

sub set_geninfo {
    my ($self, $submit, $clone) = @_;

    my $notes_file = $clone->notes_file;

    $submit->{GENINFO}->{CloneName} = $clone->name;
    $submit->{GENINFO}->{Organism} = $clone->species_name;
    $submit->{GENINFO}->{Chromosome} = $clone->chromosome;
    $submit->{GENINFO}->{PrefinisherUserList} = [ $notes_file->prefinishers ];
    $submit->{GENINFO}->{FinisherUserList} = [ $notes_file->finishers ];
    $submit->{GENINFO}->{FinishingGroup} = 'avery',
    $submit->{GENINFO}->{ProductionGroup} = 'WUGSC';
    $submit->{GENINFO}->{DigestAssemblyConfirmedByCombo} = 'consed';

    # Accession and overlaps info is probably not updated for a lot of clones
    my $project =  RefImp::Project->get(name => $clone->name);
    my $gbaccession;
    if ( $project ) {
        $gbaccession = RefImp::Clone::GbAccession->get(
            'project_id' => $project->id,
            'rank' => 1
        );
    }
    $submit->{GENINFO}->{CloneAccession} = ( $gbaccession ) ? $gbaccession->acc_number : undef;

    my $overlaps = RefImp::Project::Command::Overlaps->create(project => $project);
    $overlaps->set_overlaps;
    for my $side (qw/ right left /) {
        my $neighbor = $overlaps->neighbor_on($side);
        next if not $neighbor;
        $submit->{GENINFO}->{ucfirst($side).'OverlappingCloneName'} = $neighbor->{clone};
        $submit->{GENINFO}->{ucfirst($side).'OverlappingAccession'} = $neighbor->{acc};
    }

    return 1;
}

sub set_contig_data
{
    my ($self, $submit, $tag) = @_;

    my $contig_num = $tag->parent;
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
        $ctg_info->{ContigFinishedTo} = $self->get_unpadded_pos( $tag->parent, $self->contig_seq( $tag->parent )->length );
        $ctg_info->{EndCloneSite} = $self->get_unpadded_pos( $tag->parent, $self->contig_seq( $tag->parent )->length );
        $ctg_info->{EntireContigGoesTo} = $self->get_unpadded_pos( $tag->parent, $self->contig_seq( $tag->parent )->length );
        push @{ $submit->{COMMENTS}->{ContigData} }, $ctg_info;
    }

    if ($tag->text =~ /start/i)
    {
        if ($tag->text =~ /clone\s+site/)
        {
            $ctg_info->{StartCloneSite} = $self->get_unpadded_pos($tag->parent, $tag->start);
        }
        elsif ($tag->text =~ /finished\s+region/)
        {
            $ctg_info->{ContigFinishedFrom} = $self->get_unpadded_pos($tag->parent, $tag->start);
        }
    }
    else
    {
        if ($tag->text =~ /clone\s+site/)
        {
            $ctg_info->{EndCloneSite} = $self->get_unpadded_pos($tag->parent, $tag->stop);
        }
        elsif ($tag->text =~ /finished\s+region/)
        {
            $ctg_info->{ContigFinishedTo} = $self->get_unpadded_pos($tag->parent, $tag->stop);
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

    my $contig_num = $tag->parent;
    $contig_num =~ s/Contig//;

    my $info;
    $info->{doFinishCommentsContigNumber} = $contig_num;
    $info->{doFinishCommentsStartBP} = $self->get_unpadded_pos($tag->parent, $tag->start);
    $info->{doFinishCommentsEndBP} = $self->get_unpadded_pos($tag->parent, $tag->stop);

    push @{ $submit->{COMMENTS}->{doFinishComments} }, $info;

    return;
}

sub add_toggle
{
    my ($self, $submit, $type) = @_;

    push @{$submit->{TOGGLES}}, $type . "Toggle";

    return;
}

sub contig_seq
{
    my ($self, $contig_name, $seq) = @_;

    $self->{_contig_seqs}->{$contig_name} = $seq if defined $seq;

    return $self->{_contig_seqs}->{$contig_name};
}

sub get_base_for_padded_position
{
    my ($self, $contig_name, $padded_pos) = @_;

    return $self->contig_seq($contig_name)->get_padded_base_value( $padded_pos - 1 );
}

sub get_unpadded_pos
{
    my ($self, $contig_name, $padded_pos) = @_;

    return $self->contig_seq($contig_name)->get_transform->get_unpad_position($padded_pos);
}

sub set_start_and_end
{
    my ($self, $temp, $tag, $type) = @_;

    $temp->{ $type.'StartBP' } = $self->get_unpadded_pos($tag->parent, $tag->start);
    $temp->{ $type.'EndBP' } = $self->get_unpadded_pos($tag->parent, $tag->stop);

    return;
}

sub set_from_and_to
{
    my ($self, $temp, $tag, $type) = @_;

    $temp->{ $type . 'RegionFrom' } = $self->get_unpadded_pos($tag->parent, $tag->start);
    $temp->{ $type . 'RegionTo' } = $self->get_unpadded_pos($tag->parent, $tag->stop);

    return;
}
sub set_contig_num
{
    my ($self, $temp, $tag, $type) = @_;

    my $contig_name = $tag->parent;
    $contig_name =~ s/Contig//;

    $temp->{ $type . 'ContigNumber' } = $contig_name;

    return;
}

sub set_comment
{
    my ($self, $temp, $tag, $type) = @_;

    my $comment = $tag->text;
    $comment =~ s/^COMMENT\{\n//;
    $comment =~ s/\C\}$//;

    $temp->{ $type . 'Text' } = $comment;

    return;
}

sub set_transposon_comment
{
    my ($self, $temp, $tag, $type) = @_;

    my $comment = $tag->text;
    $comment =~ s/^COMMENT\{\n//;
    $comment =~ s/\C\}$//;

    $temp->{$type.'TextComment'} = $comment;
    $temp->{$type.'TextCommentToggle'} = 1;

    return;
}

sub set_orientation
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->text =~ /meets finishing standards:\s*(.*)\n/;
    my $orientation = $1;

    $temp->{$type.'OrientationCheckbox'} = ( defined $orientation && $orientation =~ /n/i) ? 1 : 0;

    return;
}

sub set_fin_standards
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->text =~ /meets finishing standards:\s*(.*)\n/;
    my $fin_standards = $1 || '';

    $temp->{$type.'DoesNotMeetFinishingStandardsCheckbox'} = ($fin_standards =~ /n/i) ? 1 : 0;

    return;
}


sub set_discrepancy
{
    my ($self, $temp, $tag, $type) = @_;

    $tag->text =~ /discrepancies:\s*(.*)\n/;
    my $discrepancy = $1;

    $temp->{$type.'DiscrepanciesCheckbox'} = ( defined $discrepancy && $discrepancy =~ /y/i) ? 1 : 0;

    return;
}

sub set_sizing_info
{
    my ($self, $temp, $tag, $type) = @_;

    my ($sizing) = $tag->text =~ /sizing:\s*(digest|subclone|pcr|too large to size)\s*\n/i;
    my ($subclone) = $tag->text =~ /subclone:\s*(.*)\n/;
    my ($real) = $tag->text =~ /real\/product_size:\s*(.*)\n/;
    my ($insilico) = $tag->text =~ /insilico:\s*(.*)\n/;
    my ($lib_size) = $tag->text =~ /library_size:\s*(.*)\n/;


    $temp->{$type.'SizingInfo'} = $sizing;

    $type =~ s/Comments//;

    if (defined $sizing and $sizing =~ /digest/i)
    {
        my ($enzyme) = $tag->text =~ /enzyme:\s*(\w*)\s*\n/;

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

    $tag->text =~ /DNA source:\s*(.*)\n/;
    $temp->{$type.'DNASource'} = $1;
    $tag->text =~ /Plate name:\s*(.*)\n/;
    $temp->{$type.'PlateName'} = $1;
    $tag->text =~ /Plasmid\/pcr name:\s*(.*)\n/;
    $temp->{$type.'TextComment'} = $1;
    $temp->{$type.'TextCommentToggle'} = 1;

    return;
}

sub set_finished_region_transposon
{
    my ($self, $temp, $tag) = @_;

    $temp->{TransposonCommentsSequenceRegion} = 'Finished Region';

    # Ugly
    $temp->{TransposonCommentsLastBaseBefore} = $self->get_base_for_padded_position($tag->parent, $tag->start - 1);
    $temp->{TransposonCommentsLastBaseBeforePosition} = $self->get_unpadded_pos($tag->parent, $tag->start - 1);
    $temp->{TransposonCommentsFirstBaseOf} = $self->get_base_for_padded_position($tag->parent, $tag->start);
    $temp->{TransposonCommentsFirstBaseOfPosition} = $self->get_unpadded_pos($tag->parent, $tag->start);
    $temp->{TransposonCommentsLastBaseOf} = $self->get_base_for_padded_position($tag->parent, $tag->stop);
    $temp->{TransposonCommentsLastBaseOfPosition} = $self->get_unpadded_pos($tag->parent, $tag->stop);
    $temp->{TransposonCommentsFirstBaseAfter} = $self->get_base_for_padded_position($tag->parent, $tag->stop + 1);
    $temp->{TransposonCommentsFirstBaseAfterPosition} = $self->get_unpadded_pos($tag->parent, $tag->stop + 1);

    return;
}

sub set_excised_transposon
{
    my ($self, $temp, $tag) = @_;

    # More Ugly
    $temp->{TransposonCommentsLastBaseBefore} = $self->get_base_for_padded_position($tag->parent, $tag->start);
    $temp->{TransposonCommentsLastBaseBeforePosition} = $self->get_unpadded_pos($tag->parent, $tag->start);
    $temp->{TransposonCommentsFirstBaseOf} = 'N';
    $temp->{TransposonCommentsFirstBaseOfPosition} = 'NA';
    $temp->{TransposonCommentsLastBaseOf} = 'N';
    $temp->{TransposonCommentsLastBaseOfPosition} = 'NA';
    $temp->{TransposonCommentsFirstBaseAfter} = $self->get_base_for_padded_position($tag->parent, $tag->stop);
    $temp->{TransposonCommentsFirstBaseAfterPosition} = $self->get_unpadded_pos($tag->parent, $tag->stop);

    return;
}

1;


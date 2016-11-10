package RefImp::Project::Command::Overlaps;

use strict;
use warnings 'FATAL';

use List::Util;
use Params::Validate ':types';

class RefImp::Project::Command::Overlaps {
    is => 'RefImp::Project::Command::Base',
    has_transient_optional => {
        overlaps => { is => 'ARRAY', },
    },
    doc => 'show project neighbors',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute { 
    my $self = shift;

    my $overlaps = $self->set_overlaps;
    $self->_print_overlaps($overlaps);

    return 1;
}

sub set_overlaps {
    my $self = shift;

    my $dbh = RefImp::DataSource::Oltp->get_default_handle
        or $self->fatal_message('Cannot get default database handle');
    my $sth = $dbh->prepare($self->query)
        or $self->fatal_message("Failed to prepare query:  $DBI::errstr");
    my $name = $self->project->name;
    $sth->execute($name, $name, $name)
        or $self->fatal_message("Failed to execute query: $DBI::errstr");

    my @overlaps;
    while (my $data = $sth->fetchrow_hashref()) {
        next if $data->{SIDE} eq '-';
        push @overlaps, $data;
    }
    $self->overlaps(\@overlaps);

    return 1;
}

sub neighbor_on {
    my ($self, $side) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    return List::Util::first { $_->{SIDE} =~ /$side/i } @{$self->overlaps};
}

sub _print_overlaps {
    my ($self, $overlaps) = @_;

    my @lengths = (qw/ 15 20 6 14 14 /);
    my $format = join(' ', map { "%-".$_."s" } @lengths)."\n";
    my @attrs = (qw/  CLONE_NAME ACCESSION SIDE OVERLAP_STATUS PROJECT_STATUS /);
    my $output = sprintf($format, @attrs);
    $output .= sprintf( $format, map { '-'x $_ } @lengths);

    for my $overlap ( @{$self->overlaps} ) {
        $output .= sprintf($format, map { $overlap->{$_} } @attrs);
    }

    $self->status_message($output);

    return 1;
}

sub query {
    return
    qq/
    select distinct 
    decode(ee.local_clone_name, null, (decode(ee.gap_type,2,'GAP',3,'GAP','')), ee.local_clone_name) as clone_name, 
    ee.accession_number_set as accession,
    ee.ovl as side,    
    ee.overlap_status as overlap_Status,
    p.prosta_project_status project_Status
    from
    (
        select 
            e.pos,
            case
                when pos = 0  then '-'
                when ( lag(pos,1)over(order by pos) )  = 0 then 'Right'
                when ( lead(pos,1)over(order by pos) ) = 0 then 'Left'
                else 'Other'
        end ovl,
        ( lag(pos,1)over(order by pos) ) bp,
        ( lead(pos,1)over(order by pos) ) ap,
        e.local_clone_name,
        (case pos when 0 then '-' else e.overlap_status end ) overlap_status,
        e.accession_number_set,
        e.status,
        e.gb_clone_name,
		e.gap_type
        from
        (
            select distinct             
                    e2.position - e1.position pos, 
                    e2.*,
                    case when e2.tp_id = e1.tp_id then '-' else o.status end overlap_status 
                from tp_entry e1
                inner join tp_overlap o on tp1_id = e1.tp_id or tp2_id = e1.tp_id
                inner join tp_entry e2 on (tp1_id = e2.tp_id or tp2_id = e2.tp_id) 
                where e1.tp_id in (
                    select tp_id from tp_entry where local_clone_name = ? or gb_clone_name = ?
                         union
                    select tp_id from accession_number where accession_number = ?
                )
        ) e
    ) ee
    left outer join projects p on p.name = ee.local_clone_name

    order by decode(ovl, 'Left',1,'-',2,'Right',3,4) nulls last
    /;
}

1;


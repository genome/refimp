package RefImp::Util::Tablizer;

use strict;
use warnings;

use List::Util;

sub format {
    my ($class, $rows) = @_;

    die 'No rows given to tablize!' if not $rows;
    return '' if not @$rows;

    # Get column lengths
    my @column_lengths;
    for my $row ( @$rows ) {
        for (my $y = 0; $y < @$row; $y++) {
            push @{$column_lengths[$y]}, length($row->[$y]);
        }
    }

    # Get max lengths
    my @max_lengths = map { List::Util::max(@{$_}) } @column_lengths; 

    # Format
    my @formatted_rows;
    for my $row ( @$rows ) {
        my @formatted_row;
        for ( my $x = 0; $x < @$row; $x++ ) {
            my $diff = $max_lengths[$x] - length($row->[$x]);
            push @formatted_row, $row->[$x].(' ' x $diff);
        }
        push @formatted_rows, \@formatted_row;
    }

    # Join
    join("\n", map({ join(' ', @$_) } @formatted_rows), '');

}

sub as_html {
    my ($class, $rows) = @_;

    die 'No rows given to tablize!' if not $rows;
    return '' if not @$rows;

    #my $header = shift @$lines;
	my $table = '<table><tbody>';
    #$table .= '<tr><th>' . join('</th><th>', split('\t', $header)) . '</th></tr>';
    for my $row (@$rows) {
        $table .= '<tr><td>' . join('</td><td>', @$row) . '</td></tr>';
    }
	$table .= '</tbody></table>';
	$table;
}

1;

package RefImp::Project::Command::Digest::ToConsed;

use strict;
use warnings 'FATAL';

use Cwd;
use File::Basename;

class RefImp::Project::Command::Digest::ToConsed {
    is => 'RefImp::Project::Command::Base',
    doc => 'extract digest info from sizes file',
};

sub help_detail {
    <<HELP;
Converts .sizes files in project digest directoryt into Consed friendly fragSizes files. Links the most recent fragSizes file to fragSizes.txt in the edit_dir.
HELP
}

sub execute {
    my $self = shift;
    $self->status_message('Digest sizes to consed...');

    my $project = $self->project;
    $self->status_message('Project: %s', $project->__dsiplay_name__);

    my $edit_dir = $project->edit_directory;
    $self->fatal_message('No project edit_dir directory!') if not -d $edit_dir;
    my $digest_directory = $project->digest_directory;
    $self->fatal_message('No project diest directory!') if not -d $digest_directory;

    my @sizes;
    @sizes = chomp(@sizes=`ls *sizes| sort`);

    my $project_basename = RefImp::Project::Command::Digest->project_basename($project->name);
    $self->status_message('Project basename: %s', $project_basename);

    foreach my $size_file (@sizes) {
        my %enzyme_hash;
        my %output_hash;
        my ($sizes_date) = $size_file =~ /(\S+).sizes/;

        print "sizes_file: $size_file\n";

        open SIZES, $size_file || die "couldn't open $size_file";

        while( <SIZES> ) {
            s/^\s+//g;
            next if /^$/ ;
            my ($clone_enzyme, $bands, $date)= split;

            if ( $clone_enzyme=~ /$project_basename/ ) {
                print "found $_";
                my $szEnzymeName= &get_enzyme($clone_enzyme);
                $enzyme_hash{$szEnzymeName}++;


                $output_hash{$enzyme_hash{$szEnzymeName}}.= ">$szEnzymeName\n";

                while( <SIZES> ) {
                    $output_hash{$enzyme_hash{$szEnzymeName}}.= $_;
                    chomp;
                    last if ( $_ == -1 ) ;
                }
            }
        }

        close SIZES;


        foreach my $file_number (sort {$a <=> $b} keys %output_hash){
            my $consed_out;
            my $suffix= $file_number - 1;
            $consed_out= ($file_number == 1)?
            "$edit_dir/fragSizes" . $sizes_date. ".txt":
            "$edit_dir/fragSizes" . $sizes_date . "_$suffix.txt";
            print "$consed_out\n";

            open CONSED, ">$consed_out" || die "couldn't open $consed_out for writing";
            print CONSED $output_hash{$file_number};
            close CONSED;
        }

    }

    chdir ($edit_dir) or warn "can't cd $edit_dir\n";
    unlink "fragSizes.txt" if (-l "fragSizes.txt");
    my $most_recent = `ls -t fragSizes*|head -1`;
    chomp $most_recent;
    system "ln -s $most_recent fragSizes.txt";

    return 1
}

1;


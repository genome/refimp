package RefImp::Project::Command::Digest::ToConsed;

use strict;
use warnings 'FATAL';

use Cwd;
use File::Basename;

class RefImp::Project::Command::Digest::ToConsed {
    is => '',
    has => {},
    doc => '',
};

sub help_detail {
    <<HELP;
usage sizesToConsed 
sizesToConsed.perl sizes_file
sizesToConsed.perl project_name

*where (sizes file) is the .sizes file that contains the 
actual restriction fragment sizes.

 Purpose:  converts .sizes files to Consed friendly filetype
           Creates file edit_dir/fragSizes.txt of the actual restriction
           fragment sizes.

HELP
}

sub execute {
    my $self = shift;

    my @sizes;
    my $clone;
    my $path;

# takes sizesToConsed clone   
    if(-d "$ENV{SEQMGR}/$ARGV[0]/digest/"){ 
        $clone=$ARGV[0];
        chdir "$ENV{SEQMGR}/$ARGV[0]/digest/" or die "can't cd to $ARGV[0]/digest\n";
        chomp(@sizes=`ls *sizes| sort`);
        $path=$ENV{SEQMGR};
    }else{ # sizesToConsed sizes_file in digest dir
        # users should be in digest_dir
        my $top_dir;
        @sizes=@ARGV;

        my $cwd= cwd();
        ($top_dir,$path)=&fileparse($cwd,());

        if (-d "$ENV{SEQMGR}/$top_dir/digest"){
            $clone=$top_dir; 
        }else{
            chop $path;
            ($clone,$path)=&fileparse($path,());
            chop $path;
        }
    }

    die "$path/$clone/digest does not exist!\n\n" unless -d "$path/$clone/digest";
    die "$path/$clone/edit_dir dose not exist\n\n" unless -d "$path/$clone/edit_dir";

    my $edit_dir="$path/$clone/edit_dir";
    my $clone_basename = $clone;

    print "project name is $clone\n";

    if ( $clone =~ /^C_AD-/) {
        $clone_basename = substr( $clone_basename, 5 ); 
    }elsif( $clone =~ /^(CB|JB|JE|JH)/ &&  ( length( $clone_basename ) > 4 )){
        $clone_basename = substr( $clone_basename, 2 );
    }else {
        $clone_basename = substr( $clone_basename, 4 ); 
    }

    print "clone base name: $clone_basename\n";
#exit;

    foreach my $size_file (@sizes){
        my %enzyme_hash;
        my %output_hash;
        my ($sizes_date) = $size_file =~ /(\S+).sizes/;

        print "sizes_file: $size_file\n";

        open SIZES, $size_file || die "couldn't open $size_file";

        while( <SIZES> ) {
            s/^\s+//g;
            next if /^$/ ;
            my ($clone_enzyme, $bands, $date)= split;

            if ( $clone_enzyme=~ /$clone_basename/ ) {
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


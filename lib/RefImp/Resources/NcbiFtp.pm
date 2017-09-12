package Refimp::Resources::NcbiFtp;

use strict;
use warnings;

use Net::FTP;

class Refimp::Resources::NcbiFtp {
    is => 'UR::Singleton',
};

sub connect {
    my $class = shift;

    my $ftphost = Refimp::Config::get('ncbi_ftp_host');
    $class->status_message('FTP host: %s', $ftphost);
    my $ftp = Net::FTP->new($ftphost);
    if ($@) {
        $class->fatal_message('Could not connect to FTP Host %s! %s', $ftphost, $@);
    }

    $ftp->login( Refimp::Config::get('ncbi_ftp_user'), Refimp::Config::get('ncbi_ftp_password') );
    $ftp->binary;
    $ftp->quot('prompt');

    return $ftp;
}

1;


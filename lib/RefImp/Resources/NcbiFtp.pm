package RefImp::Resources::NcbiFtp;

use strict;
use warnings;

use RefImp;

use Net::FTP;

class RefImp::Resources::NcbiFtp {
    is => 'UR::Singleton',
};

sub connect {
    my $class = shift;

    my $ftphost = RefImp::Config::get('ncbi_ftp_host');
    $class->status_message('FTP host: %s', $ftphost);
    my $ftp = Net::FTP->new($ftphost);
    if ($@) {
        $class->fatal_message('Could not connect to FTP Host %s! %s', $ftphost, $@);
    }

    $ftp->login( RefImp::Config::get('ncbi_ftp_user'), RefImp::Config::get('ncbi_ftp_password') );
    $ftp->binary;
    $ftp->quot('prompt');

    return $ftp;
}

1;


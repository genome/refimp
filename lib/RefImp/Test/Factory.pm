package RefImp::Test::Factory;

use strict;
use warnings;

use Net::FTP;
use Sub::Install;
use Test::MockObject;

my $ftp;
sub setup_test_ftp {
    my $class = shift;

    return $ftp if $ftp;

    my $ftp = Test::MockObject->new;
    $ftp->set_true('login');
    $ftp->set_true('cwd');
    $ftp->set_true('binary');
    $ftp->set_true('quot');
    $ftp->set_true('put');
    Sub::Install::reinstall_sub({
            code => sub { $ftp },
            as => 'new',
            into => 'Net::FTP',
        });

    return $ftp;
}

1;


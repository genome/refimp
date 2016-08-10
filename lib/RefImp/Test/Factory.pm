package RefImp::Test::Factory;

use strict;
use warnings;

use RefImp;

use Net::FTP;
use RefImp::Resources::LimsRestApi;
use Sub::Install;
use Test::MockObject;

sub default_clone_name { 'HMPB-AAD13A05'; }

my $clone;
sub setup_test_clone {
    my $class = shift;

    return $clone if $clone;

    RefImp::Test->set_seqmgr_test_data_directory;

    my $name = default_clone_name();
    $clone = RefImp::Clone->create(
        name => $name,
        status => 'active',
        type => 'plasmid',
    ) or die "Failed to create clone for $name";
    -d $clone->project_directory or die "Clone dir does not exists for $name";

    my $lims_rest_api = Test::MockObject->new;
    my %taxonomy = (
        species_name => 'human',
        species_latin_name => 'Homo sapiens',
        chromosome => 7,
    );
    $lims_rest_api->mock(
        'query', 
        sub{
            my ($self, $object, $method) = @_;
            return $taxonomy{$method};
        },
    );
    Sub::Install::reinstall_sub({
            code => sub{ $lims_rest_api },
            into => 'RefImp::Resources::LimsRestApi',
            as => 'new'
        });

    return $clone;
}

my $project;
sub setup_test_project {
    my $class = shift;

    return $project if $project;

    RefImp::Test->set_seqmgr_test_data_directory;

    my $name = default_clone_name();
    $project = RefImp::Project->create(
        name => $name,
    ) or die "Failed to create project for $name";

    return $project;
};

my $user;
sub setup_test_user {
    my $class = shift;

    return $user if $user;

    my $user = RefImp::User->create(
        unix_login => 'bobama',
    ) or die "Failed to create test user!";

    my $ei_id = -11;
    my @p = (
        { name => 'finish', status => 'active'},
        { name => 'prefinish', status => 'inactive'},
        { name => 'qc', status => 'inactive'},
    );
    for my $p ( @p ) {
        my $function = $user->add_function(
            id => $ei_id--,
            status => $p->{status},
        ) or die "Failed to create test user function!";
        my $work_function = RefImp::User::WorkFunction->create(
            id => $function->id,
            %$p
        ) or die "Failed to create test work function!";
    }

    return $user;
}

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


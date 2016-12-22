#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp;
use File::Spec;
use Test::Exception;
use Test::More tests => 4;

my $pkg_name = 'RefImp::Role::PropertyValuesFromFile';
use_ok($pkg_name) or die;

class FromFileTest {
    has_many_optional => {
        names => { is => 'Text', },
    },
};
RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('FromFileTest', 'names');

subtest 'errors' => sub{
    plan tests => 1;

    throws_ok(
        sub{ RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('FromFileTest', 'blah'); },
        qr/No property for blah/,
        'class_properties_can_load_from_file fails with unknown property',
    );
};

subtest 'create with strings' => sub{
    plan tests => 4;

    my $cmd = FromFileTest->create();
    ok($cmd, 'create w/o names');
    ok(!$cmd->names, 'no names');

    my @names = (qw/ Luke Leia /);
    $cmd = FromFileTest->create(names => \@names);
    ok($cmd, 'create w/ names');
    is_deeply([$cmd->names], \@names, 'names');

};

subtest 'create with file' => sub{
    plan tests => 2;

    my $names_file = File::Spec->join(TestEnv::test_data_directory_for_package($pkg_name), 'names.txt');
    my $cmd = FromFileTest->create(names => $names_file);
    ok($cmd, 'create w/ file');
    is_deeply([$cmd->names], ['Han Solo', 'Chewbaca'], 'names');

};

done_testing();
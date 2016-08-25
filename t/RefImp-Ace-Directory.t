#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::More tests => 1;
use Test::Exception;

my %setup;
subtest 'setup' => sub{
    plan tests => 4;

    my $pkg = 'RefImp::Ace::Directory';
    use_ok($pkg) or die;

    throws_ok(sub{ $pkg->create; }, qr/No path given/, 'create fails w/o path');
    throws_ok(sub{ $pkg->create(path => 'blah'); }, qr/Path does not exist/, 'create fails w/ invalid path');

    my $path = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'edit_dir');
    $setup{ace_path} = $pkg->create(path => $path);
    ok($setup{ace_path}, 'create ace path');

};

done_testing();

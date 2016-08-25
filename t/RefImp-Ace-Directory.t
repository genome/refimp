#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::More tests => 2;
use Test::Exception;

my %setup;
subtest 'setup' => sub{
    plan tests => 4;

    my $pkg = 'RefImp::Ace::Directory';
    use_ok($pkg) or die;

    throws_ok(sub{ $pkg->create; }, qr/No path given/, 'create fails w/o path');
    throws_ok(sub{ $pkg->create(path => 'blah'); }, qr/Path does not exist/, 'create fails w/ invalid path');

    my $path = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'edit_dir');
    $setup{ace_dir} = $pkg->create(path => $path);
    ok($setup{ace_dir}, 'create ace path');

};

subtest 'acefiles and aces' => sub{
    plan tests => 1;

    my @acefiles = $setup{ace_dir}->all_acefiles;
    my @expected_aces = (qw/ project.ace  project.ace.0 /);
    my @expected_acefiles = map { File::Spec->join($setup{ace_dir}->path, $_) } @expected_aces;
    is_deeply(\@acefiles, \@expected_acefiles, 'all_acefiles');

};

done_testing();

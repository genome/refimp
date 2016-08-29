#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Temp;
use File::Spec;
use IO::File;
use Test::More tests => 4;
use Test::Exception;

my %setup;
subtest 'setup' => sub{
    plan tests => 4;

    my $pkg = 'RefImp::Ace::Directory';
    use_ok($pkg) or die;

    throws_ok(sub{ $pkg->create; }, qr/No path given/, 'create fails w/o path');
    throws_ok(sub{ $pkg->create(path => 'blah'); }, qr/Path does not exist/, 'create fails w/ invalid path');

    my $path = File::Temp::tempdir(CLEANUP => 1);
    #my $path = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'edit_dir');
    $setup{ace_dir} = $pkg->create(path => $path);
    ok($setup{ace_dir}, 'create ace path');

    $setup{expected_aces} = [qw/ project.ace.0  project.ace /];
    my @basenames_and_content = (
        [ 'project.ace', 'AS 1 1' ],
        [ 'not-an-ace-file.ace', 'Not really an ace file!' ],
        [ 'project.fasta.log', 'The assembly went fine!' ],
        [ 'project.ace.0', 'AS 1 1' ],
    );
    for my $bnc ( @basenames_and_content ) {
        sleep 1 if $bnc->[0] =~ /\.0$/;
        my $fh = IO::File->new(File::Spec->join($path, $bnc->[0]), 'w');
        $fh->print($bnc->[1]."\n");
        $fh->flush;
        $fh->close;
    }
    $setup{expected_acefiles} = [ map { File::Spec->join($path, $_) } @{$setup{expected_aces}} ];

};

subtest 'acefiles and aces' => sub{
    plan tests => 2;

    my @acefiles = $setup{ace_dir}->acefiles;
    is_deeply(\@acefiles, $setup{expected_acefiles}, 'acefiles');
    is_deeply([$setup{ace_dir}->aces], $setup{expected_aces}, 'aces');

};

subtest 'recent acefile and ace' => sub{
    plan tests => 2;

    my $expected_recent_ace = $setup{expected_aces}[0];
    is($setup{ace_dir}->recent_acefile, File::Spec->join($setup{ace_dir}->path, $expected_recent_ace), 'recent acefile');
    is($setup{ace_dir}->recent_ace, $expected_recent_ace, 'recent ace');

};

subtest 'no acefiles' => sub {
    plan tests => 5;

    my $ad = RefImp::Ace::Directory->create(path => '.');
    ok($ad, 'create ace directory w/o aces');
    ok(!$ad->acefiles, 'no acefiles');
    ok(!$ad->aces, 'no aces');
    ok(!$ad->recent_acefile, 'no recent acefile');
    ok(!$ad->recent_ace, 'no recent ace');
};

done_testing();

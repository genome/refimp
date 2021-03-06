#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 3;
use Test::Exception;

my %test = ( class => 'Pacbio::Run', );
subtest 'new' => sub{
    plan tests => 9;

    use_ok($test{class}) or die;

    $test{data_dir} = dir( TestEnv::test_data_directory_for_class($test{class}) )->subdir('6U00E3');
    ok(-d "$test{data_dir}", "example run directory exists");

    my $run = $test{class}->new(directory => $test{data_dir}, machine_type => 'rsii');

    ok($run, 'create run');
    ok($run->directory, 'directory');
    is($run->__name__, join(' ', $run->directory, $run->machine_type), '__name__');

    $test{run} = $run;

    throws_ok(sub{ $test{class}->new; }, qr/No directory given/, 'fails w/o directory');
    throws_ok(sub{ $test{class}->new(directory => dir('blah')); }, qr/Directory given does not exist/, 'fails w/ invalid directory');
    throws_ok(sub{ $test{class}->new(directory => $test{data_dir}); }, qr/No machine_type given/, 'fails w/o machine_type');
    throws_ok(sub{ $test{class}->new(directory => $test{data_dir}, machine_type => 'blah'); }, qr/Invalid machine_type given/, 'fails w/ invalid machine_type');

};

subtest 'analyses' => sub{
    plan tests => 6;

    my $run = $test{run};
	my $analyses = $run->analyses;
    ok($analyses, 'run analyses');
    is(@$analyses, 16, 'correct number of analyses');
    is($run->analyses_count, 16, 'analyses_count');

	my $sample_analyses = $run->analyses_for_sample(qr/HG02818/);
    is(@$sample_analyses, 14, 'correct number of sample analyses');
    my $expected_sample_analyses = [ grep { $_->library_name =~ /HG02818/ } @$analyses ];
    is_deeply($sample_analyses, $expected_sample_analyses, 'analyses_for_sample');

    throws_ok(sub{ $test{run}->analyses_for_sample; }, qr/No sample name regex given/, 'analyses_for_sample fails w/o sample name regex');

};

subtest 'instrument_model' => sub{
    plan tests => 3;

    my $run = $test{class}->new(directory => $test{data_dir}, machine_type => 'rsii');
    is($run->instrument_model, "PacBio RS II", "instrument_model for rsii");
    $run->machine_type('sequel');
    is($run->instrument_model, "PacBio Sequel", "instrument_model for sequel");
    $run->machine_type('blash');
    throws_ok(sub{ $run->instrument_model; }, qr//, 'fails for unknown machine type');

};

done_testing();

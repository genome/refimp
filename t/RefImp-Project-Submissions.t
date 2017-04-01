#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Temp;
use Test::Exception;
use Test::More tests => 3;

my $pkg = 'RefImp::Project::Submissions';
use_ok($pkg) or die;

my $project = RefImp::Project->get(1);
TestEnv::LimsRestApi::setup;
my $taxon = $project->taxon;

subtest 'file names' => sub{
    plan tests => 3;

    is($pkg->submit_form_file_name_for_project($project), join('.', $project->name, 'submit', 'form'), 'submit_form_file_name');
    throws_ok(
        sub{ $pkg->submit_info_yml_file_name_for_project; },
        qr/but 2 were expected/,
        'submit yml file name fails w/o clone'
    );
    is($pkg->submit_info_yml_file_name_for_project($project), join('.', $project->name, 'submit', 'yml'), 'submit_form_file_name');

};

subtest 'templates' => sub{
    plan tests => 1;

    my $analysis_directory = RefImp::Config::get('analysis_directory');
    is(
        $pkg->raw_sqn_template_for_taxon($taxon),
        File::Spec->join($analysis_directory, 'templates', 'raw_'.$taxon->species_short_name.'_template.sqn'),
        'raw_sqn_template_for_taxon',
    );

};

done_testing();

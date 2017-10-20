#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;
use Test::More tests => 3;

my $pkg = 'RefImp::Tenx::Command::Alignment::List';
use_ok($pkg) or die;
is($pkg->__meta__->property_meta_for_name('subject_class_name')->default_value, 'RefImp::Tenx::Alignment', 'subject_class_name');
is_deeply($pkg->__meta__->property_meta_for_name('show')->default_value, 'id,reads.sample_name,reference.name,directory', 'show');
done_testing();

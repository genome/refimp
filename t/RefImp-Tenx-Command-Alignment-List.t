#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 2;

my $pkg = 'RefImp::Tenx::Command::Alignment::List';
use_ok($pkg) or die;
is($pkg->__meta__->property_meta_for_name('subject_class_name')->default_value, 'RefImp::Tenx::Alignment', 'subject_class_name');
done_testing();

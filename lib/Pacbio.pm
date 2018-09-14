package Pacbio;

use strict;
use warnings 'FATAL';

our $VERSION = '0.010100';

use UR;

UR::Object::Type->define(
    class_name => 'Pacbio',
    is => ['UR::Namespace'],
    english_name => 'pacbio helpers',
);

1;

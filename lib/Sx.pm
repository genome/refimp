package Sx;

use strict;
use warnings 'FATAL';

our $VERSION = '0.010100';

use UR;

UR::Object::Type->define(
    class_name => 'Sx',
    is => ['UR::Namespace'],
    english_name => 'sequence transform',
);

1;

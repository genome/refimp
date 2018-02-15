package RefImp::Assembly::Command::Submission::Info;

use strict;
use warnings 'FATAL';

use RefImp::Assembly::SubmissionInfo;

class RefImp::Assembly::Command::Submission::Info {
    is => 'Command::V2',
    doc => 'print submission yaml to fill out',
};

sub help_detail { 'Print detailed info about submission fields.' }

sub execute { print RefImp::Assembly::SubmissionInfo->help_doc_for_attributes }

1;

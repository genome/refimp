package RefImp::Clone::GbAccession;

use strict;
use warnings;

=pod

GB_ACCESSIONS	GSC::GBAccession	oltp	production

    ACC_NUMBER         acc_number VARCHAR2(16)          (pk)
    CENTER             center     VARCHAR2(30) NULLABLE     
    PROJECT_PROJECT_ID project_id NUMBER(10)            (fk)
    RANK               rank       NUMBER(1)                 
    VERSION            version    NUMBER(2)    NULLABLE     

=cut

class RefImp::Clone::GbAccession { 
    table_name => 'gb_accessions',
    id_by => {
        acc_number => { is => 'Text', }
    },
    has => {
        center => { is => 'Text', },
        project_id => { is => 'Text', column_name => 'PROJECT_PROJECT_ID', },
        rank => { is => 'text', },
        version  => { is => 'text', },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

1;


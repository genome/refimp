package RefImp::User;

use strict;
use warnings;

use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Resources::LDAP;

=doc 2016-05-27

GSC_USERS	GSC::User	oltp	production

    ACTIVE_WORK_FUNCTION_ID  active_work_function_id  NUMBER(10)    NULLABLE (fk)    
    BS_BARCODE               barcode                  VARCHAR2(16)           (fk)    
    CREATION_EVENT_ID        creation_event_id        NUMBER(10)    NULLABLE (fk)    
    DEFAULT_WORK_FUNCTION_ID default_work_function_id NUMBER(10)    NULLABLE (fk)    
    EMAIL                    email                    VARCHAR2(64)                   
  x FIRST_NAME               first_name               VARCHAR2(32)  NULLABLE         
    GRA_GRADE                gra_grade                VARCHAR2(4)   NULLABLE         
  x GU_ID                    gu_id                    NUMBER(10)             (pk)    
    HIRE_DATE                hire_date                DATE(19)                       
    INITIALS                 initials                 VARCHAR2(4)   NULLABLE         
  x LAST_NAME                last_name                VARCHAR2(32)  NULLABLE         
    MIDDLE_NAME              middle_name              VARCHAR2(20)  NULLABLE         
    TERMINATION_DATE         termination_date         DATE(19)      NULLABLE         
  x UNIX_LOGIN               unix_login               VARCHAR2(16)           (unique)
    USER_COMMENT             user_comment             VARCHAR2(140) NULLABLE         
    US_USER_STATUS           user_status              VARCHAR2(16)           (fk)    

=cut

class RefImp::User {
    table_name => 'gsc_users',
    id_by => {
        id => { is => 'Integer', column_name => 'gu_id', },
    },
    has_optional => {
        first_name => { is => 'Text', doc => 'First name of the user.', },
        last_name => { is => 'Text', doc => 'Last name of the user.', },
        unix_login => { is => 'Text', doc => 'Login for the user.', },
    },
    has_many => {
        functions => {
            is => 'RefImp::User::Function',
            reverse_as => 'user',
            doc => 'User functions.',
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

sub email_domain { 'wustl.edu' }
sub email {
    my $self = shift;
    # Try LDAP first...
    my $mail = RefImp::Resources::LDAP->mail_for_unix_login( $self->unix_login );
    return $mail if $mail;
    # Return the unix_login and domain
    join('@', $self->unix_login, $self->email_domain);
}

sub first_initial { uc substr($_[0]->first_name, 0, 1); }
sub last_name_uc { sprintf('%s', join(' ', map { ucfirst } split(' ', $_[0]->last_name))); }

1;


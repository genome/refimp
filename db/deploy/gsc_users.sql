-- Deploy refimp:gsc_users to sqlite

BEGIN;

CREATE TABLE gsc_users(
        active_work_function_id NUMBER(10),
        bs_barcode VARCHAR2(16),
        creation_event_id NUMBER(10),
        default_work_function_id NUMBER(10),
        email VARCHAR2(64),
        first_name VARCHAR2(32),
        gra_grade VARCHAR2(4),
        gu_id NUMBER(10),
        hire_date DATE,
        initials VARCHAR2(4),
        last_name VARCHAR2(32),
        middle_name VARCHAR2(20),
        termination_date DATE,
        unix_login VARCHAR2(16),
        us_user_status VARCHAR2(16),
        user_comment VARCHAR2(140),
        CONSTRAINT gsc_users_pk PRIMARY KEY(gu_id)
);

COMMIT;

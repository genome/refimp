-- Deploy refimp:gsc_user_function to sqlite

BEGIN;

CREATE TABLE user_function(
        creation_event_id NUMBER(10),
        ei_id NUMBER(10),
        function_id NUMBER(10),
        gu_id NUMBER(10),
        status VARCHAR2(16),
	CONSTRAINT gsc_user_function_pk PRIMARY KEY (ei_id),
	CONSTRAINT gsc_user_function_pk FOREIGN KEY(gu_id) REFERENCES gsc_user(gu_id)
);

COMMIT;

-- Deploy refimp:work_function to sqlite

BEGIN;

CREATE TABLE work_function (
	creation_event_id NUMBER(10),
	description VARCHAR2(256),
	function_id NUMBER(10),
	name VARCHAR2(100) NOT NULL,
	permission VARCHAR2(16),
	status VARCHAR2(8),
	type VARCHAR2(32),
	CONSTRAINT work_function_pk PRIMARY KEY(function_id)
);

COMMIT;

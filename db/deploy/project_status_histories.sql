-- Deploy refimp:project_status_histories to sqlite

BEGIN;

CREATE TABLE project_status_histories (
	project_project_id NUMBER(10),
	ps_project_status VARCHAR2(22),
	status_date DATE,
	CONSTRAINT psh_project_fk FOREIGN KEY(project_project_id) REFERENCES project(project_id)
);

COMMIT;

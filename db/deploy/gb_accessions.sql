-- Deploy refimp:gb_accessions to sqlite

BEGIN;

CREATE TABLE gb_accessions (
        acc_number VARCHAR2(16),
        center VARCHAR2(30),
        project_project_id NUMBER(10),
        rank NUMBER(1),
        version NUMBER(2),
        CONSTRAINT gb_accessions_pk PRIMARY KEY(acc_number),
        CONSTRAINT gb_accessions_project_fk FOREIGN KEY(project_project_id) REFERENCES project(project_id)
);

COMMIT;

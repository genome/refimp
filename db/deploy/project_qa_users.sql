-- Deploy refimp:project_qa_users to sqlite

BEGIN;

CREATE TABLE project_finishers(
        project_project_id NUMBER(10),
        ei_ei_id NUMBER(10),
        CONSTRAINT project_finishers_project_fk FOREIGN KEY(project_project_id) REFERENCES project(project_id)
);

CREATE TABLE project_prefinishers(
        project_project_id NUMBER(10),
        ei_ei_id NUMBER(10),
        CONSTRAINT project_prefinishers_project_fk FOREIGN KEY(project_project_id) REFERENCES project(project_id)
);

CREATE TABLE project_savers(
        project_project_id NUMBER(10),
        ei_ei_id NUMBER(10),
        CONSTRAINT project_savers_project_fk FOREIGN KEY(project_project_id) REFERENCES project(project_id)
);

COMMIT;

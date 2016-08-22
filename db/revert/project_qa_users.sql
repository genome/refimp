-- Revert refimp:project_qa_users from sqlite

BEGIN;

DROP TABLE project_finishers;
DROP TABLE project_prefinishers;
DROP TABLE project_savers;

COMMIT;

-- Revert refimp:project_status_histories from sqlite

BEGIN;

DROP TABLE project_status_histories;

COMMIT;

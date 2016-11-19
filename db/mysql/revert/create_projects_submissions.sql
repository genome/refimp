-- Revert refimp:create_projects_submissions from mysql

BEGIN;

DROP TABLE IF EXISTS projects_submissions;

COMMIT;

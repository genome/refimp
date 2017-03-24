-- Revert refimp:create_projects_submissions from sqlite

BEGIN;

DROP TABLE IF EXISTS projects_submissions;

COMMIT;

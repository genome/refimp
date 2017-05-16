-- Revert refimp:create_projects from mysql

BEGIN;

DROP TABLE IF EXISTS projects;

COMMIT;

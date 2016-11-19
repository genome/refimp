-- Revert refimp:create_projects from sqlite

BEGIN;

DROP TABLE IF EXISTS projects;

COMMIT;

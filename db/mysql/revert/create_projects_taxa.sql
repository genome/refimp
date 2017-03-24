-- Revert refimp:create_project_taxa from mysql

BEGIN;

DROP TABLE IF EXISTS projects_taxa;

COMMIT;

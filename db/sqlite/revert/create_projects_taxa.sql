-- Revert refimp:create_project_taxa from sqlite

BEGIN;

DROP TABLE IF EXISTS projects_taxa;

COMMIT;

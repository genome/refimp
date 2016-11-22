-- Revert refimp:create_project_taxons from mysql

BEGIN;

DROP TABLE IF EXISTS projects_taxons;

COMMIT;

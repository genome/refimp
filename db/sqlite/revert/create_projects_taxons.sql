-- Revert refimp:create_project_taxons from sqlite

BEGIN;

DROP TABLE IF EXISTS projects_taxons;

COMMIT;

-- Revert refimp:create_assemblies_submissions from sqlite

BEGIN;

DROP TABLE IF EXISTS assemblies_submissions;

COMMIT;

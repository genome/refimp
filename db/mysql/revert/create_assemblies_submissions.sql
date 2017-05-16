-- Revert refimp:create_assemblies_submissions from mysql

BEGIN;

DROP TABLE IF EXISTS assemblies_submissions;

COMMIT;

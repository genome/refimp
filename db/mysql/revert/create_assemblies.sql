-- Revert refimp:create_assemblies from mysql

BEGIN;

DROP TABLE IF EXISTS assemblies;

COMMIT;

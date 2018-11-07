-- Revert create_assemblies from sqlite

BEGIN;

DROP TABLE IF EXISTS assemblies;

COMMIT;

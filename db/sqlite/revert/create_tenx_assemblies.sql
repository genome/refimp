-- Revert tenx:create_tenx_assemblies from sqlite

BEGIN;

DROP TABLE IF EXISTS tenx_assemblies;

COMMIT;

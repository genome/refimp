-- Revert tenx:create_tenx_assemblies from mysql

BEGIN;

DROP TABLE IF EXISTS tenx_assemblies;

COMMIT;

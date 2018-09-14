-- Revert tenx:create_tenx_references from mysql

BEGIN;

DROP TABLE IF EXISTS tenx_references;

COMMIT;

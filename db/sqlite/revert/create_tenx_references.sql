-- Revert tenx:create_tenx_references from sqlite

BEGIN;

DROP TABLE IF EXISTS tenx_references;

COMMIT;

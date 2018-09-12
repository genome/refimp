-- Revert tenx:create_tenx_reads from sqlite

BEGIN;

DROP TABLE IF EXISTS tenx_reads;

COMMIT;

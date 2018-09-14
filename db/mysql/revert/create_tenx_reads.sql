-- Revert tenx:create_tenx_reads from mysql

BEGIN;

DROP TABLE IF EXISTS tenx_reads;

COMMIT;

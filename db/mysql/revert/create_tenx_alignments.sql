-- Revert tenx:create_tenx_alignments from mysql

BEGIN;

DROP TABLE IF EXISTS tenx_alignments;

COMMIT;

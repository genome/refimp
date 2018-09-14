-- Revert tenx:create_tenx_alignments from sqlite

BEGIN;

DROP TABLE IF EXISTS tenx_alignments;

COMMIT;

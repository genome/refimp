-- Revert create_reads from sqlite

BEGIN;

DROP TABLE IF EXISTS sequence_reads;

COMMIT;

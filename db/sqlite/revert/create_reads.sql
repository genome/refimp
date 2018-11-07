-- Revert create_reads from sqlite

BEGIN;

DROP TABLE IF EXISTS reads;

COMMIT;

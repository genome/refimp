-- Revert create_alignments from sqlite

BEGIN;

DROP TABLE IF EXISTS alignments;

COMMIT;

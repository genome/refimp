-- Revert create_refseqs from sqlite

BEGIN;

DROP TABLE IF EXISTS refseqs;

COMMIT;

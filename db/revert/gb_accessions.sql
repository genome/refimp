-- Revert refimp:gb_accessions from sqlite

BEGIN;

DROP TABLE gb_accessions;

COMMIT;

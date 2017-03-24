-- Revert refimp:create_taxa from sqlite

BEGIN;

DROP TABLE IF EXISTS taxa;

COMMIT;

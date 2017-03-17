-- Revert refimp:create_taxa from mysql

BEGIN;

DROP TABLE IF EXISTS taxa;

COMMIT;

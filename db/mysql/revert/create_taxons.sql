-- Revert refimp:create_taxons from mysql

BEGIN;

DROP TABLE IF EXISTS taxons;

COMMIT;

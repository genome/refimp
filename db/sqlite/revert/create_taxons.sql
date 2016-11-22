-- Revert refimp:create_taxons from sqlite

BEGIN;

DROP TABLE IF EXISTS taxons;

COMMIT;

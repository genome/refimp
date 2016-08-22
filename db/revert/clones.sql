-- Revert refimp:clones from sqlite

BEGIN;

DROP TABLE clones;

COMMIT;

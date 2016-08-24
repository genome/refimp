-- Revert refimp:gsc_users from sqlite

BEGIN;

DROP TABLE gsc_users;

COMMIT;

-- Revert refimp:create_users from sqlite

BEGIN;

DROP TABLE IF EXISTS users;

COMMIT;

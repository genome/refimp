-- Revert refimp:create_users from mysql

BEGIN;

DROP TABLE IF EXISTS users;

COMMIT;

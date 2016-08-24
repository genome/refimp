-- Revert refimp:gsc_user_function from sqlite

BEGIN;

DROP TABLE user_function;

COMMIT;

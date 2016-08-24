-- Revert refimp:work_function from sqlite

BEGIN;

DROP TABLE work_function;

COMMIT;

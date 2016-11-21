-- Revert refimp:create_projects_users from sqlite

BEGIN;

DROP TABLE IF EXISTS projects_users;

COMMIT;

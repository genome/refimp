-- Revert refimp:create_projects_users from mysql

BEGIN;

DROP TABLE IF EXISTS projects_users;

COMMIT;

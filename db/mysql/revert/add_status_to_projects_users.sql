-- Revert refimp:add_status_to_projects_users from mysql
-- requires projects_users

BEGIN;

ALTER TABLE projects_users DROP COLUMN status;

COMMIT;

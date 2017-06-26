-- Verify refimp:add_status_to_projects_users on mysql

BEGIN;

SELECT status FROM projects_users WHERE 0;

ROLLBACK;

-- Verify refimp:add_status_to_projects_users on sqlite

BEGIN;

SELECT status FROM projects_users WHERE 0;

ROLLBACK;

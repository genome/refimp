-- Verify refimp:create_projects_users on sqlite

BEGIN;

SELECT
        project_id, user_id, purpose
FROM projects_users
WHERE 0;

ROLLBACK;

-- Verify refimp:create_projects_users on mysql

BEGIN;

SELECT
        project_id, user_id, purpose
FROM projects_users
WHERE 0;

ROLLBACK;

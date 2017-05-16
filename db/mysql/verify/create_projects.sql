-- Verify refimp:create_projects on mysql

BEGIN;

SELECT
	id, name, directory, status, clone_type
FROM projects
WHERE 0;

ROLLBACK;

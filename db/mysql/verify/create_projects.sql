-- Verify refimp:create_projects on sqlite

BEGIN;

SELECT
	id, name, directory, status, clone_type
FROM projects
WHERE 0;

ROLLBACK;

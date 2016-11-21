-- Verify refimp:create_users on sqlite

BEGIN;

SELECT
	id, name, first_name, last_name, email
FROM users
WHERE 0;

ROLLBACK;

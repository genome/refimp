-- Verify refimp:create_users on mysql

BEGIN;

SELECT
	id, name, first_name, last_name, email
FROM users
WHERE 0;

ROLLBACK;

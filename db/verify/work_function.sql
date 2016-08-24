-- Verify refimp:work_function on sqlite

BEGIN;

SELECT creation_event_id, description, function_id, name, permission, status, type
FROM work_function
WHERE 0;

ROLLBACK;

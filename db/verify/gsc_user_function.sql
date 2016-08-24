-- Verify refimp:gsc_user_function on sqlite

BEGIN;

SELECT creation_event_id, ei_id, function_id, gu_id, status
FROM user_function
WHERE 0;

ROLLBACK;

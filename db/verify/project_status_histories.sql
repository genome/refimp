-- Verify refimp:project_status_histories on sqlite

BEGIN;

SELECT project_project_id, ps_project_status, status_date
FROM project_status_histories
WHERE 0;

ROLLBACK;

-- Verify refimp:gb_accessions on sqlite

BEGIN;

SELECT acc_number, center, project_project_id, rank, version
FROM gb_accessions
WHERE 0;

ROLLBACK;

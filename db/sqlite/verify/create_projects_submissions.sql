-- Verify refimp:create_projects_submissions on sqlite

BEGIN;

SELECT
        project_id, submitted_on, accession_id, directory, phase, project_size
FROM projects_submissions
WHERE 0;

ROLLBACK;

-- Verify refimp:create_projects_submissions on mysql

BEGIN;

SELECT
        project_id, submitted_on, accession_id, directory, phase, project_size
FROM projects_submissions
WHERE 0;

ROLLBACK;

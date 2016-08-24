-- Verify refimp:project_qa_users on sqlite

BEGIN;

SELECT project_project_id, ei_ei_id FROM project_finishers WHERE 0;
SELECT project_project_id, ei_ei_id FROM project_prefinishers WHERE 0;
SELECT project_project_id, ei_ei_id FROM project_savers WHERE 0;

ROLLBACK;

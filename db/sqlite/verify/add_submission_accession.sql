-- Verify refimp:add_submission_accession on sqlite

BEGIN;

SELECT accession_id FROM assemblies_submissions WHERE 0;

ROLLBACK;

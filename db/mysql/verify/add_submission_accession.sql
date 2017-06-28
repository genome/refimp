-- Verify refimp:add_submission_accession on mysql

BEGIN;

SELECT accession_id FROM assemblies_submissions WHERE 0;

ROLLBACK;

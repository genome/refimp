-- Revert refimp:add_submission_accession from mysql
-- requires assemblies_submissions

BEGIN;

ALTER TABLE assemblies_submissions DROP COLUMN accession_id;

COMMIT;

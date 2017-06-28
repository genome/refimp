-- Revert refimp:add_submission_accession from sqlite
-- requires assemblies_submissions

BEGIN;

ALTER TABLE assemblies_submissions DROP COLUMN accession_id;

COMMIT;

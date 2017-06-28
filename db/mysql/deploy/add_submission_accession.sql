-- Deploy refimp:add_submission_accession to mysql
-- requires assemblies_submissions

BEGIN;

ALTER TABLE assemblies_submissions ADD accession_id VARCHAR(32);

COMMIT;

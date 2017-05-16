-- Verify refimp:create_assemblies_submissions on sqlite

BEGIN;

SELECT
	submission_id, assembly_id, bioproject, biosample, directory, submitted_on,
	submission_yml, version 
FROM assemblies_submissions
WHERE 0;

ROLLBACK;

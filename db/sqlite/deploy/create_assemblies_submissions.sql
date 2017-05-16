-- Deploy refimp:create_assemblies_submissions to sqlite
-- requires assemblies

BEGIN;

CREATE TABLE IF NOT EXISTS assemblies_submissions (
	submission_id VARCHAR(32),
	assembly_id VARCHAR(32),
	bioproject VARCHAR(32),
	biosample VARCHAR(32),
	directory VARCHAR(128),
	submitted_on DATE,
	submission_yml VARCHAR(2048),
	version VARCHAR(8),

	CONSTRAINT asssub_assembly_fk FOREIGN KEY(assembly_id) REFERENCES assemblies(id)
);

CREATE INDEX IF NOT EXISTS asssub_assembly ON assemblies_submissions(assembly_id);
CREATE INDEX IF NOT EXISTS asssub_submitted_on ON assemblies_submissions(submitted_on);

COMMIT;

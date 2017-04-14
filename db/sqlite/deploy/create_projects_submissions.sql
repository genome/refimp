-- Deploy refimp:create_projects_submissions to mysql
-- requires projects

BEGIN;

CREATE TABLE IF NOT EXISTS projects_submissions (
	project_id VARCHAR(32),
	submitted_on DATE,
	accession_id VARCHAR(32),
	directory VARCHAR(128),
	phase VARCHAR(16),
	project_size INTEGER,

	CONSTRAINT prosub_project_fk FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX IF NOT EXISTS prosub_project ON projects_submissions(project_id);
CREATE INDEX IF NOT EXISTS prosub_submitted_on ON projects_submissions(submitted_on);

COMMIT;

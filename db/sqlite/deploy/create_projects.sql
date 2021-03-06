-- Deploy refimp:create_projects to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS projects (
        id VARCHAR(32),
	name VARCHAR(64),
	directory VARCHAR(128),
	status VARCHAR(32),
	clone_type VARCHAR(32),

	CONSTRAINT projects_pk PRIMARY KEY(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS projects_name on projects(name);

COMMIT;

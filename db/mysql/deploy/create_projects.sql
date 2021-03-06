-- Deploy refimp:create_projects to mysql

BEGIN;

CREATE TABLE IF NOT EXISTS projects (
        id VARCHAR(32),
	name VARCHAR(64),
	directory VARCHAR(128),
	status VARCHAR(32),
	clone_type VARCHAR(32),

	CONSTRAINT projects_pk PRIMARY KEY(id),
	UNIQUE(name)
);

COMMIT;

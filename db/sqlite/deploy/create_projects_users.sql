-- Deploy refimp:create_projects_users to sqlite
-- requires projects
-- requires users

BEGIN;

CREATE TABLE IF NOT EXISTS projects_users (
        project_id VARCHAR(32),
        user_id VARCHAR(32),
	purpose VARCHAR(16),
	claimed_on DATE,

	CONSTRAINT prouse_pk PRIMARY KEY (project_id, user_id, purpose)
	CONSTRAINT prouse_project_fk FOREIGN KEY(project_id) REFERENCES projects(id),
	INDEX(project_id),
	CONSTRAINT prouse_user_fk FOREIGN KEY(user_id) REFERENCES users(id),
	INDEX(user_id),
);

COMMIT;

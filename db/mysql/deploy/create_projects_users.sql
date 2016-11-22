-- Deploy refimp:create_projects_users to mysql
-- requires projects
-- requires users

BEGIN;

CREATE TABLE IF NOT EXISTS projects_users (
        project_id VARCHAR(32),
        user_id VARCHAR(32),
	purpose VARCHAR(16),
	claimed_on DATE,

	CONSTRAINT prouse_project_fk FOREIGN KEY(project_id) REFERENCES projects(id),
	CONSTRAINT prouse_user_fk FOREIGN KEY(user_id) REFERENCES users(id),
	UNIQUE(project_id, user_id, purpose)
);

COMMIT;

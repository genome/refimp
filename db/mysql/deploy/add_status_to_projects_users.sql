-- Deploy refimp:add_status_to_projects_users to mysql
-- requires project_users

BEGIN;

ALTER TABLE projects_users ADD status VARCHAR(256);

COMMIT;

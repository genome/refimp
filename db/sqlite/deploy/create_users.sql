-- Deploy refimp:create_users to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(32),
	name VARCHAR(16),
	first_name VARCHAR(32),
	last_name VARCHAR(32),
	email VARCHAR(64),

	CONSTRAINT users_pk PRIMARY KEY(id)
);

CREATE UNIQUE INDEX user_email_idx ON users (email);
CREATE INDEX user_name_idx ON users (name);

COMMIT;

-- Deploy refimp:create_users to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(32),
	name VARCHAR(16),
	first_name VARCHAR(32),
	last_name VARCHAR(32),
	email VARCHAR(64),

	CONSTRAINT users_id_pk PRIMARY KEY(id),
	UNIQUE(name),
	UNIQUE(email)
);

COMMIT;

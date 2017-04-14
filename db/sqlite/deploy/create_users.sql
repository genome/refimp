-- Deploy refimp:create_users to mysql

BEGIN;

CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(32),
	name VARCHAR(16),
	first_name VARCHAR(32),
	last_name VARCHAR(32),
	email VARCHAR(64),

	CONSTRAINT users_pk PRIMARY KEY(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS users_name ON users(name);
CREATE UNIQUE INDEX IF NOT EXISTS users_email ON users(email);

COMMIT;

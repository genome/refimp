-- Deploy tenx:create_tenx_references to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS tenx_references (
        id VARCHAR(32),
	name VARCHAR(64),
	directory VARCHAR(256),
	taxon_id VARCHAR(32),

	UNIQUE(name),
	CONSTRAINT tenx_references_pk PRIMARY KEY(id)
);

COMMIT;

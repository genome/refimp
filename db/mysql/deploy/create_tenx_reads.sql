-- Deploy tenx:create_tenx_reads to mysql

BEGIN;

CREATE TABLE IF NOT EXISTS tenx_reads (
        id VARCHAR(32),
	directory VARCHAR(256),
	sample_name VARCHAR(64),
	targets_path VARCHAR(256),

	CONSTRAINT tenxreads_pk PRIMARY KEY(id)
);

COMMIT;

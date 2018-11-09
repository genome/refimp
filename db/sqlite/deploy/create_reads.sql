-- Deploy create_reads to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS sequence_reads (
        id VARCHAR(32),
	sample_name VARCHAR(64),
	url VARCHAR(256),
	tech VARCHAR(16),
	targets_url VARCHAR(256),

	CONSTRAINT reads_pk PRIMARY KEY(id)
);

COMMIT;

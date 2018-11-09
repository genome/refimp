-- Deploy create_refseqs to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS refseqs (
        id VARCHAR(32),
	name VARCHAR(64),
	url VARCHAR(256),
	tech VARCHAR(16),
	taxon_id VARCHAR(32),

	UNIQUE(name),
	CONSTRAINT ref_pk PRIMARY KEY(id)
	CONSTRAINT reftax_fk FOREIGN KEY(taxon_id) REFERENCES taxa(id)
);

COMMIT;

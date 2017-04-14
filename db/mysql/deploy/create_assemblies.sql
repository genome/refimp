-- Deploy refimp:create_assemblies to mysql
-- requires taxa

BEGIN;

CREATE TABLE IF NOT EXISTS assemblies (
        id VARCHAR(32),
	name VARCHAR(64),
	directory VARCHAR(128),
	taxon_id VARCHAR(32),

	UNIQUE(name),
	CONSTRAINT assemblies_pk PRIMARY KEY(id),
	CONSTRAINT assemblies_taxon_fk FOREIGN KEY(taxon_id) REFERENCES taxa(id)
);

COMMIT;

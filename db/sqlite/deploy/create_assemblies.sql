-- Deploy refimp:create_assemblies to sqlite
-- requires taxa
-- requires reads

BEGIN;

CREATE TABLE IF NOT EXISTS assemblies (
        id VARCHAR(32),
	name VARCHAR(64),
	url VARCHAR(256),
	tech VARCHAR(16),
	status VARCHAR(16),
	taxon_id VARCHAR(32),
	reads_id VARCHAR(32),

	UNIQUE(name),
	CONSTRAINT assemblies_pk PRIMARY KEY(id),
	CONSTRAINT assemblies_taxon_fk FOREIGN KEY(taxon_id) REFERENCES taxa(id),
	CONSTRAINT assemblies_reads_fk FOREIGN KEY(reads_id) REFERENCES reads(id)

);

COMMIT;

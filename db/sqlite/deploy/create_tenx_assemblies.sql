-- Deploy tenx:create_tenx_assemblies to sqlite
-- requires tenx_reads

BEGIN;

CREATE TABLE IF NOT EXISTS tenx_assemblies (
        id VARCHAR(32),
	directory VARCHAR(256),
	reads_id VARCHAR(256),
	status VARCHAR(16),

	CONSTRAINT tenxassemblies_pk PRIMARY KEY(id),
	CONSTRAINT tenxassemblies_reference_fk FOREIGN KEY(reads_id) REFERENCES tenx_reads(id)
);

COMMIT;

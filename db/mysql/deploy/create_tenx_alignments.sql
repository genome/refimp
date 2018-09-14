-- Deploy tenx:create_tenx_alignments to mysql
-- requires tenx_references
-- requires tenx_reads

BEGIN;

CREATE TABLE IF NOT EXISTS tenx_alignments (
        id VARCHAR(32),
	directory VARCHAR(256),
	reads_id VARCHAR(32),
	reference_id VARCHAR(32),
	status VARCHAR(16),

	CONSTRAINT tenxalignments_pk PRIMARY KEY(id),
	CONSTRAINT tenxalignments_reference_fk FOREIGN KEY(reference_id) REFERENCES tenx_references(id),
	CONSTRAINT tenxalignments_reads_fk FOREIGN KEY(reads_id) REFERENCES tenx_reads(id)
);

COMMIT;

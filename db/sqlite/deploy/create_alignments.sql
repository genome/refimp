-- Deploy create_alignments to sqlite
-- requires refseqs
-- requires reads

BEGIN;

CREATE TABLE IF NOT EXISTS alignments (
        id VARCHAR(32),
	url VARCHAR(256),
	tech VARCHAR(16),
	status VARCHAR(16),
	reads_id VARCHAR(256),
	refseq_id VARCHAR(32),

	CONSTRAINT aln_pk PRIMARY KEY(id),
	CONSTRAINT alnref_fk FOREIGN KEY(refseq_id) REFERENCES refseqs(id)
	CONSTRAINT alnrds_fk FOREIGN KEY(reads_id) REFERENCES reads(id)
);

COMMIT;

-- Deploy refimp:create_project_taxa to mysql
-- requires projects
-- requires taxa

BEGIN;

CREATE TABLE IF NOT EXISTS projects_taxa (
	project_id VARCHAR(32),
	taxon_id VARCHAR(32),
	chromosome VARCHAR(16),

	CONSTRAINT protax_pk PRIMARY KEY (project_id, taxon_id),
	CONSTRAINT protax_project_fk FOREIGN KEY(project_id) REFERENCES projects(id),
	INDEX(project_id),
	CONSTRAINT protax_taxon_fk FOREIGN KEY(taxon_id) REFERENCES taxa(id),
	INDEX(taxon_id)
);

COMMIT;

-- Deploy refimp:create_project_taxons to sqlite
-- requires projects
-- requires taxons

BEGIN;

CREATE TABLE IF NOT EXISTS projects_taxons (
	project_id VARCHAR(32),
	taxon_id VARCHAR(32),
	chromosome VARCHAR(16),

	CONSTRAINT protax_pk PRIMARY KEY (project_id, taxon_id),
	CONSTRAINT protax_project_fk FOREIGN KEY(project_id) REFERENCES projects(id),
	CONSTRAINT protax_taxon_fk FOREIGN KEY(taxon_id) REFERENCES taxons(id)
);

CREATE INDEX protax_project_idx ON projects_taxons (project_id);
CREATE INDEX protax_taxon_idx ON projects_taxons (taxon_id);

COMMIT;

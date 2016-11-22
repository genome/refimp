-- Deploy refimp:create_project_taxons to mysql

BEGIN;

CREATE TABLE IF NOT EXISTS projects_taxons (
	project_id VARCHAR(32),
	taxon_id VARCHAR(32),
	chromosome VARCHAR(16),

	CONSTRAINT protax_project_fk FOREIGN KEY(project_id) REFERENCES projects(id),
	CONSTRAINT protax_taxon_fk FOREIGN KEY(taxon_id) REFERENCES taxons(id),
	UNIQUE(project_id, taxon_id)
);

COMMIT;

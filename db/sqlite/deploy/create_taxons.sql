-- Deploy refimp:create_taxons to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS taxons (
        id VARCHAR(32),
	name VARCHAR(64),
	species_name VARCHAR(64),
	strain_name VARCHAR(64),

	CONSTRAINT taxons_id_pk PRIMARY KEY(id),
	UNIQUE(species_name, strain_name)
);

COMMIT;

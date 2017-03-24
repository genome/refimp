-- Deploy refimp:create_taxa to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS taxa (
        id VARCHAR(32),
	name VARCHAR(64),
	species_name VARCHAR(64),
	strain_name VARCHAR(64),

	CONSTRAINT taxa_pk PRIMARY KEY(id),
	UNIQUE(species_name, strain_name)
);

COMMIT;

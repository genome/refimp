-- Verify refimp:create_taxons on mysql

BEGIN;

SELECT
	id, name, species_name, strain_name
FROM taxons
WHERE 0;

ROLLBACK;

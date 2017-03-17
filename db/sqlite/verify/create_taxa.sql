-- Verify refimp:create_taxa on sqlite

BEGIN;

SELECT
	id, name, species_name, strain_name
FROM taxa
WHERE 0;

ROLLBACK;

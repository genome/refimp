-- Verify refimp:create_assemblies on sqlite

BEGIN;

SELECT
	id, name, directory, taxon_id
FROM assemblies
WHERE 0;

ROLLBACK;

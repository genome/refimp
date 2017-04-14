-- Verify refimp:create_assemblies on mysql

BEGIN;

SELECT
	id, name, directory, taxon_id
FROM assemblies
WHERE 0;

ROLLBACK;

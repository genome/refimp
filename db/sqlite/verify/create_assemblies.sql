-- Verify refimp:create_assemblies on sqlite

BEGIN;

SELECT
	id, name, url, tech, status, taxon_id, reads_id
FROM assemblies
WHERE 0;

ROLLBACK;

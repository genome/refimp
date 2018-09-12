-- Verify tenx:create_tenx_references on mysql

BEGIN;

SELECT
	id, name, directory, taxon_id
FROM tenx_references
WHERE 0;

ROLLBACK;

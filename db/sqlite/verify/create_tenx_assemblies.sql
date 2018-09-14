-- Verify tenx:create_tenx_assemblies on sqlite

BEGIN;

SELECT
	id, directory, reads_id, status
FROM tenx_assemblies
WHERE 0;

ROLLBACK;

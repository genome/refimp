-- Verify tenx:create_tenx_assemblies on sqlite

BEGIN;

SELECT
	id, url, reads_id, status
FROM tenx_assemblies
WHERE 0;

ROLLBACK;

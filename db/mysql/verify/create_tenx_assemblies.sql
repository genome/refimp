-- Verify tenx:create_tenx_assemblies on mysql

BEGIN;

SELECT
	id, url, reads_id, status
FROM tenx_assemblies
WHERE 0;

ROLLBACK;

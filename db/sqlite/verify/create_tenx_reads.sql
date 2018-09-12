-- Verify tenx:create_tenx_reads on sqlite

BEGIN;

SELECT
	id, directory, sample_name, targets_path
FROM tenx_reads
WHERE 0;

COMMIT;

-- Verify tenx:create_tenx_alignments on sqlite

BEGIN;

SELECT
	id, directory, reads_id, reference_id, status
FROM tenx_alignments
WHERE 0;

ROLLBACK;

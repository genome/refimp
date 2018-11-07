-- Verify create_reads on sqlite

BEGIN;

SELECT
	id, sample_name, url, targets_url
FROM reads
WHERE 0;

COMMIT;

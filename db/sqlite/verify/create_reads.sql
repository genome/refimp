-- Verify create_reads on sqlite

BEGIN;

SELECT
	id, sample_name, url, tech, targets_url
FROM reads
WHERE 0;

COMMIT;

-- Verify create_alignments on sqlite

BEGIN;

SELECT
	id, url, tech, status, reads_id, refseq_id
FROM alignments
WHERE 0;

ROLLBACK;

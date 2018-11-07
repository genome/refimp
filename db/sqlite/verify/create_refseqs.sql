-- Verify create_refseqs on sqlite

BEGIN;

SELECT
	id, name, url, taxon_id
FROM refseqs
WHERE 0;

ROLLBACK;

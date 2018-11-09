-- Verify create_refseqs on sqlite

BEGIN;

SELECT
	id, name, url, tech, taxon_id
FROM refseqs
WHERE 0;

ROLLBACK;

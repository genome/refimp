-- Verify refimp:create_project_taxa on sqlite

BEGIN;

SELECT
	project_id, taxon_id, chromosome
FROM projects_taxa
WHERE 0;

ROLLBACK;

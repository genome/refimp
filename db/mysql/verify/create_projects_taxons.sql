-- Verify refimp:create_project_taxons on mysql

BEGIN;

SELECT
	project_id, taxon_id, chromosome
FROM projects_taxons
WHERE 0;

ROLLBACK;
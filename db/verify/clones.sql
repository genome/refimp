-- Verify clone

BEGIN;

SELECT
	chr_chromosome ,clo_id ,clone_date_received ,clone_extension ,clone_name
	clone_size ,clopre_clone_prefix ,cs_clone_status ,ct_clone_type ,gap
	map_location, map_order 
FROM clones
WHERE 0;

ROLLBACK;

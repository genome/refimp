-- Verify refimp:create_disk_assignments_groups_and_volumes on sqlite

BEGIN;

SELECT
	dg_id, disk_group_name
FROM disk_group
WHERE 0;

SELECT
	dv_id, mount_path
FROM disk_volume
WHERE 0;

SELECT
	dv_id, dg_id
FROM disk_volume_group
WHERE 0;

SELECT
      	dg_id, dv_id
FROM disk_assignment
WHERE 0;

ROLLBACK;

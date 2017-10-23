-- Revert refimp:create_disk_assignments_groups_and_volumes from sqlite

BEGIN;

DROP TABLE IF EXISTS disk_group;
DROP TABLE IF EXISTS disk_volume;
DROP TABLE IF EXISTS disk_volume_group;
DROP TABLE IF EXISTS disk_assignment;

COMMIT;

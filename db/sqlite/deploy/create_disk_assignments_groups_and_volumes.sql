-- Deploy refimp:create_disk_assignments_groups_and_volumes to sqlite

BEGIN;

CREATE TABLE IF NOT EXISTS disk_group (
        dg_id VARCHAR(32),
	disk_group_name VARCHAR(32),

	CONSTRAINT dg_pk PRIMARY KEY(dg_id)
);

CREATE TABLE IF NOT EXISTS disk_volume (
        dv_id VARCHAR(32),
	mount_path VARCHAR(32),

	CONSTRAINT dv_pk PRIMARY KEY(dv_id)
);


CREATE TABLE IF NOT EXISTS disk_assignment (
      	dg_id VARCHAR(32),
	dv_id VARCHAR(32),

	CONSTRAINT da_pk PRIMARY KEY(dg_id, dv_id),
	CONSTRAINT da_dg_fk FOREIGN KEY(dg_id) REFERENCES disk_group(dg_id),
	CONSTRAINT da_dv_fk FOREIGN KEY(dv_id) REFERENCES disk_volume(dv_id)
);

COMMIT;

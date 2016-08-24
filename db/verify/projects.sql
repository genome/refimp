-- Verify projects

BEGIN;

SELECT
	archival_date, consensus_directory, date_last_assembled, estimated_size, estimated_size_from_ctgs
	gro_group_name, name, no_assemble_traces, no_contigs, no_ct_gt_1kb, no_q20_bases, pp_purpose,
	priority, project_id, prosta_project_status, spanned_gap, spanned_gsc_gap, target
FROM projects
WHERE 0;

ROLLBACK;

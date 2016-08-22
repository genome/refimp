-- Deploy refimp:projects to sqlite

BEGIN;

CREATE TABLE projects (
        aprox_coverage NUMBER,
        archival_date DATE,
        consensus_directory VARCHAR2(150),
        date_last_assembled DATE,
        estimated_size NUMBER,
        estimated_size_from_ctgs NUMBER(8),
        gro_group_name VARCHAR2(64),
        name VARCHAR2(64),
        no_assemble_traces NUMBER,
        no_contigs NUMBER,
        no_ct_gt_1kb NUMBER,
        no_q20_bases NUMBER,
        pp_purpose VARCHAR2(32),
        priority NUMBER(1),
        project_id NUMBER(10),
        prosta_project_status VARCHAR2(22),
        spanned_gap NUMBER(10),
        spanned_gsc_gap NUMBER(10),
        target NUMBER(5),
        CONSTRAINT projects_pk PRIMARY KEY(project_id)
);

COMMIT;

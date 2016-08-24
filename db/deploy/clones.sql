-- Deploy refimp:clones to sqlite

BEGIN;

CREATE TABLE clones(
        chr_chromosome VARCHAR2(8),
        clo_id NUMBER(15),
        clone_date_received DATE,
        clone_extension VARCHAR2(4),
        clone_name VARCHAR2(64) NOT NULL,
        clone_size VARCHAR2(16),
        clopre_clone_prefix VARCHAR2(16),
        cs_clone_status VARCHAR2(64),
        ct_clone_type VARCHAR2(25),
        gap VARCHAR2(2),
        map_location VARCHAR2(64),
        map_order VARCHAR2(64),
        CONSTRAINT clones_pk PRIMARY KEY(clo_id)
);

COMMIT;

-- Deploy refimp:test_data to sqlite

BEGIN;

INSERT OR IGNORE INTO projects (id, name, clone_type) VALUES ('1', 'HMPB-AAD13A05', 'bac');

INSERT OR IGNORE INTO taxa (id, name, species_name) VALUES ('1', 'human', 'homo sapiens');
INSERT OR IGNORE INTO taxa (id, name, species_name) VALUES ('2', 'eastern oyster', 'crassostrea virginica');

INSERT OR IGNORE INTO users (id, name, first_name, last_name, email) VALUES ('1', 'bobama', 'barack', 'obama', 'obama@bestprezever.com');

INSERT OR IGNORE INTO projects_taxa (project_id, taxon_id, chromosome) VALUES ('1', '1', '7');

INSERT OR IGNORE INTO assemblies (id, name, tech) VALUES ('101', 'TENX-ASSEMBLY', 'tenx');
INSERT OR IGNORE INTO assemblies (id, name, tech) VALUES ('102', 'PACBIO-ASSEMBLY', 'pacbio');

COMMIT;

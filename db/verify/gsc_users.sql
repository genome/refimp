-- Verify refimp:gsc_users on sqlite

BEGIN;

SELECT active_work_function_id, bs_barcode, creation_event_id, default_work_function_id, email,
	first_name, gra_grade, gu_id, hire_date, initials, last_name, middle_name,
	termination_date, unix_login, us_user_status, user_comment
FROM gsc_users
WHERE 0;

ROLLBACK;

-- Change date dd/mm/YYYY to YYYY-mm-dd format

ALTER TABLE hospital_beds
ALTER COLUMN fiscal_year_begin_date DATE;

ALTER TABLE hospital_beds
ALTER COLUMN fiscal_year_end_date DATE;

ALTER TABLE Hospital_data.dbo.HCAHPS_data
ALTER COLUMN start_date DATE;

ALTER TABLE Hospital_data.dbo.HCAHPS_data
ALTER COLUMN end_date DATE;


-- Hospital_beds --

WITH hospital_beds_prep AS -- create CTEs
(
SELECT
	FORMAT(provider_ccn, '000000') as provider_ccn, -- create ccn number to 6 digit as format 000000
	hospital_name,
	fiscal_year_begin_date,
	fiscal_year_end_date,
	number_of_beds,
	row_number() OVER (PARTITION BY provider_ccn ORDER BY fiscal_year_end_date DESC) AS nth_row -- search for duplicate hospital
FROM Hospital_data.dbo.hospital_beds
)

SELECT 
	provider_ccn,
	COUNT(*) AS count_of_rows
FROM hospital_beds_prep
WHERE nth_row = 1				-- row number = 2 mean duplicate data or old data
GROUP BY provider_ccn
ORDER BY count(*) DESC


-- HCAHPS_data --

SELECT 
	RIGHT(REPLICATE('0', 6) + facility_id, 6) AS provider_ccn, -- create facility_id to 6 digit as format 000000
	*
FROM Hospital_data.dbo.HCAHPS_data as hachps


-- Join HCAHPS_data to Hospital_beds

WITH hospital_beds_prep AS -- create CTEs
(
SELECT
	RIGHT(REPLICATE('0', 6) + CAST(provider_ccn AS VARCHAR(6)), 6) AS provider_ccn, -- create ccn number to 6 digit as format 000000
	hospital_name,
	fiscal_year_begin_date,
	fiscal_year_end_date,
	number_of_beds,
	row_number() OVER (PARTITION BY provider_ccn ORDER BY fiscal_year_end_date DESC) AS nth_row -- search for duplicate hospital
FROM Hospital_data.dbo.hospital_beds
)

SELECT 
	RIGHT(REPLICATE('0', 6) + CAST(hcahps.facility_id AS VARCHAR(6)), 6) AS facility_id, -- create facility_id to 6 digit as format 000000
	beds.provider_ccn,
	hcahps.*,
	beds.number_of_beds,
	beds.fiscal_year_begin_date,
	beds.fiscal_year_end_date
FROM Hospital_data.dbo.HCAHPS_data AS hcahps
LEFT JOIN hospital_beds_prep AS beds
	ON hcahps.facility_id = beds.provider_ccn
AND beds.nth_row = 1								-- select only lasted update data
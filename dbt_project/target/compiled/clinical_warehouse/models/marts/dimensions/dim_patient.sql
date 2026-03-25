

WITH patients AS (
    SELECT * FROM CLINICAL_WAREHOUSE.SILVER_STAGING.stg_patients
),
with_sk AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY patient_id)   AS patient_sk,
        patient_id                                AS patient_natural_key,
        patient_first_name,
        patient_last_name,
        birthdate,
        ssn,
        address,
        city,
        zip_code,
        gender,
        race,
        ethnicity,
        marital_status,
        state,
        county,
        age_years,
        age_group,
        is_alive,
        healthcare_expenses_usd,
        healthcare_coverage_usd
    FROM patients
)
SELECT -1 AS patient_sk, 'UNKNOWN' AS patient_natural_key,
    '[REDACTED]' AS patient_first_name, '[REDACTED]' AS patient_last_name,
    NULL::DATE AS birthdate, '***-**-****' AS ssn,
    '[REDACTED]' AS address, 'Unknown' AS city, 'Unknown' AS zip_code,
    'Unknown' AS gender, 'Unknown' AS race, 'Unknown' AS ethnicity,
    'Unknown' AS marital_status, 'Unknown' AS state, 'Unknown' AS county,
    NULL AS age_years, 'Unknown' AS age_group, NULL AS is_alive,
    NULL AS healthcare_expenses_usd, NULL AS healthcare_coverage_usd
UNION ALL
SELECT * FROM with_sk
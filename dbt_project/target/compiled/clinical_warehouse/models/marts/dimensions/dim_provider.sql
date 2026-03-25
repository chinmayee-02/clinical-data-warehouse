

WITH providers AS (
    SELECT * FROM CLINICAL_WAREHOUSE.SILVER_STAGING.stg_providers
),
with_sk AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY provider_id)  AS provider_sk,
        provider_id                               AS provider_natural_key,
        provider_name,
        gender,
        specialty,
        state,
        city,
        zip_code,
        encounter_utilization,
        CASE
            WHEN LOWER(specialty) LIKE '%cardio%'       THEN 'Cardiology'
            WHEN LOWER(specialty) LIKE '%general%'       THEN 'General Practice'
            WHEN LOWER(specialty) LIKE '%emergency%'     THEN 'Emergency Medicine'
            WHEN LOWER(specialty) LIKE '%pediatric%'     THEN 'Pediatrics'
            WHEN LOWER(specialty) LIKE '%oncology%'      THEN 'Oncology'
            WHEN LOWER(specialty) LIKE '%mental%'
              OR LOWER(specialty) LIKE '%psych%'         THEN 'Mental Health'
            WHEN LOWER(specialty) LIKE '%orthopedic%'    THEN 'Orthopedics'
            ELSE 'Other Specialties'
        END                                       AS specialty_group
    FROM providers
)
SELECT -1 AS provider_sk, 'UNKNOWN' AS provider_natural_key,
    'Unknown' AS provider_name, 'Unknown' AS gender, 'Unknown' AS specialty,
    'Unknown' AS state, 'Unknown' AS city, 'Unknown' AS zip_code,
    0 AS encounter_utilization, 'Unknown' AS specialty_group
UNION ALL
SELECT * FROM with_sk
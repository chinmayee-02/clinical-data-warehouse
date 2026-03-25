{{ config(materialized='view', schema='SILVER_STAGING', tags=['staging']) }}

SELECT
    "patient"                                             AS patient_id,
    "encounter"                                           AS encounter_id,
    NULLIF(TRIM("code"), '')                              AS condition_code,
    NULLIF(TRIM("description"), '')                       AS condition_description,
    TRY_TO_DATE("start", 'YYYY-MM-DD')                    AS onset_date,
    TRY_TO_DATE("stop", 'YYYY-MM-DD')                     AS resolution_date,
    CASE WHEN "stop" IS NULL OR TRIM("stop") = '' THEN TRUE ELSE FALSE END AS is_chronic,
    LEFT(TRIM("code"), 1)                                 AS icd10_chapter,
    "_fivetran_synced"                                    AS _fivetran_synced
FROM CLINICAL_WAREHOUSE.BRONZE.CONDITIONS
WHERE "patient" IS NOT NULL
  AND "code" IS NOT NULL

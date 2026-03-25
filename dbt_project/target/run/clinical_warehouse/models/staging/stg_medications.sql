
  create or replace   view CLINICAL_WAREHOUSE.SILVER_STAGING.stg_medications
  
  
  
  
  as (
    

SELECT
    "patient"                                             AS patient_id,
    "payer"                                               AS payer_id,
    "encounter"                                           AS encounter_id,
    NULLIF(TRIM("code"), '')                              AS medication_code,
    NULLIF(TRIM("description"), '')                       AS medication_name,
    NULLIF(TRIM("reasoncode"), '')                        AS reason_code,
    NULLIF(TRIM("reasondescription"), '')                 AS reason_description,
    TRY_TO_DATE("start", 'YYYY-MM-DD')                    AS prescription_start_date,
    TRY_TO_DATE("stop", 'YYYY-MM-DD')                     AS prescription_stop_date,
    CASE WHEN "stop" IS NULL OR TRIM("stop") = '' THEN TRUE ELSE FALSE END AS is_active,
    TRY_CAST("base_cost" AS FLOAT)                        AS base_cost_usd,
    TRY_CAST("payer_coverage" AS FLOAT)                   AS payer_coverage_usd,
    TRY_CAST("dispenses" AS INTEGER)                      AS dispense_count,
    TRY_CAST("totalcost" AS FLOAT)                        AS total_cost_usd,
    "_fivetran_synced"                                    AS _fivetran_synced
FROM CLINICAL_WAREHOUSE.BRONZE.MEDICATIONS
WHERE "patient" IS NOT NULL
  AND "code" IS NOT NULL
  );


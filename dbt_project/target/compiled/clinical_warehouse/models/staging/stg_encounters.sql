

SELECT
    "id"                                                      AS encounter_id,
    TRY_TO_TIMESTAMP("start")                                 AS encounter_start_ts,
    TRY_TO_TIMESTAMP("stop")                                  AS encounter_stop_ts,
    TRY_TO_DATE("start")                                      AS encounter_date,
    DATEDIFF('minute',TRY_TO_TIMESTAMP("start"),TRY_TO_TIMESTAMP("stop")) AS duration_minutes,
    "patient"                                                 AS patient_id,
    "organization"                                            AS organization_id,
    "provider"                                                AS provider_id,
    "payer"                                                   AS payer_id,
    NULLIF(TRIM("encounterclass"), '')                        AS encounter_class,
    CASE LOWER(TRIM("encounterclass"))
        WHEN 'ambulatory'  THEN 'Outpatient'
        WHEN 'outpatient'  THEN 'Outpatient'
        WHEN 'inpatient'   THEN 'Inpatient'
        WHEN 'emergency'   THEN 'Emergency'
        WHEN 'urgentcare'  THEN 'Urgent Care'
        WHEN 'wellness'    THEN 'Wellness'
        WHEN 'hospice'     THEN 'Hospice'
        ELSE 'Other'
    END                                                       AS encounter_type,
    NULLIF(TRIM("code"), '')                                  AS encounter_code,
    NULLIF(TRIM("description"), '')                           AS encounter_description,
    NULLIF(TRIM("reasoncode"), '')                            AS reason_code,
    NULLIF(TRIM("reasondescription"), '')                     AS reason_description,
    TRY_CAST("base_encounter_cost" AS FLOAT)                  AS base_cost_usd,
    TRY_CAST("total_claim_cost" AS FLOAT)                     AS total_claim_cost_usd,
    TRY_CAST("payer_coverage" AS FLOAT)                       AS payer_coverage_usd,
    GREATEST(0, COALESCE(TRY_CAST("total_claim_cost" AS FLOAT),0)
               - COALESCE(TRY_CAST("payer_coverage" AS FLOAT),0)) AS patient_oop_cost_usd,
    "_fivetran_synced"                                        AS _fivetran_synced
FROM CLINICAL_WAREHOUSE.BRONZE.ENCOUNTERS
WHERE "id" IS NOT NULL
  AND "patient" IS NOT NULL
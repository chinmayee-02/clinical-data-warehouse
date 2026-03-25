
  create or replace   view CLINICAL_WAREHOUSE.SILVER_STAGING.stg_payers
  
  
  
  
  as (
    

SELECT
    "id"                                                  AS payer_id,
    NULLIF(TRIM("name"), '')                              AS payer_name,
    UPPER(NULLIF(TRIM("state_headquartered"), ''))        AS state,
    TRY_CAST("amount_covered" AS FLOAT)                   AS total_amount_covered_usd,
    TRY_CAST("amount_uncovered" AS FLOAT)                 AS total_amount_uncovered_usd,
    TRY_CAST("revenue" AS FLOAT)                          AS total_revenue_usd,
    TRY_CAST("unique_customers" AS INTEGER)               AS unique_members,
    TRY_CAST("covered_encounters" AS INTEGER)             AS covered_encounter_count,
    TRY_CAST("uncovered_encounters" AS INTEGER)           AS uncovered_encounter_count,
    TRY_CAST("qols_avg" AS FLOAT)                         AS avg_quality_of_life_score,
    TRY_CAST("member_months" AS FLOAT)                    AS member_months,
    CASE
        WHEN TRY_CAST("amount_covered" AS FLOAT) + TRY_CAST("amount_uncovered" AS FLOAT) > 0
        THEN ROUND(TRY_CAST("amount_covered" AS FLOAT) /
            (TRY_CAST("amount_covered" AS FLOAT) + TRY_CAST("amount_uncovered" AS FLOAT)) * 100, 2)
    END                                                   AS coverage_rate_pct,
    "_fivetran_synced"                                    AS _fivetran_synced
FROM CLINICAL_WAREHOUSE.BRONZE.PAYERS
WHERE "id" IS NOT NULL
  );



  
    

create or replace transient table CLINICAL_WAREHOUSE.GOLD.dim_payer
    
    
    
    as (

WITH payers AS (
    SELECT * FROM CLINICAL_WAREHOUSE.SILVER_STAGING.stg_payers
),
with_sk AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY payer_id)     AS payer_sk,
        payer_id                                  AS payer_natural_key,
        payer_name,
        state,
        unique_members,
        member_months,
        total_amount_covered_usd,
        total_amount_uncovered_usd,
        total_revenue_usd,
        coverage_rate_pct,
        avg_quality_of_life_score,
        covered_encounter_count,
        uncovered_encounter_count,
        CASE
            WHEN LOWER(payer_name) LIKE '%medicare%'  THEN 'Medicare'
            WHEN LOWER(payer_name) LIKE '%medicaid%'  THEN 'Medicaid'
            WHEN payer_name = 'NO_INSURANCE'          THEN 'Uninsured'
            ELSE 'Commercial'
        END                                       AS payer_type
    FROM payers
)
SELECT -1 AS payer_sk, 'UNKNOWN' AS payer_natural_key, 'Unknown' AS payer_name,
    'Unknown' AS state, 0 AS unique_members, 0 AS member_months,
    NULL AS total_amount_covered_usd, NULL AS total_amount_uncovered_usd,
    NULL AS total_revenue_usd, NULL AS coverage_rate_pct,
    NULL AS avg_quality_of_life_score, 0 AS covered_encounter_count,
    0 AS uncovered_encounter_count, 'Unknown' AS payer_type
UNION ALL
SELECT * FROM with_sk
    )
;


  
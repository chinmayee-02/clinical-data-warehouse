
  
    

create or replace transient table CLINICAL_WAREHOUSE.GOLD.fact_encounter
    
    
    
    as (

WITH encounters AS (
    SELECT * FROM CLINICAL_WAREHOUSE.SILVER_STAGING.stg_encounters
    
)

SELECT
    e.encounter_id,
    COALESCE(p.patient_sk,   -1)    AS patient_sk,
    COALESCE(pv.provider_sk, -1)    AS provider_sk,
    COALESCE(py.payer_sk,    -1)    AS payer_sk,
    COALESCE(c.condition_sk, -1)    AS primary_condition_sk,
    COALESCE(d.date_sk,      -1)    AS date_sk,
    e.encounter_class,
    e.encounter_type,
    e.encounter_code,
    e.encounter_description,
    e.encounter_start_ts,
    e.encounter_stop_ts,
    e.duration_minutes,
    COALESCE(e.base_cost_usd, 0)            AS base_cost_usd,
    COALESCE(e.total_claim_cost_usd, 0)     AS total_claim_cost_usd,
    COALESCE(e.payer_coverage_usd, 0)       AS payer_coverage_usd,
    COALESCE(e.patient_oop_cost_usd, 0)     AS patient_oop_cost_usd,
    CASE
        WHEN e.total_claim_cost_usd > 0
        THEN ROUND(e.payer_coverage_usd / e.total_claim_cost_usd * 100, 2)
    END                                     AS payer_coverage_rate_pct,
    CASE WHEN e.encounter_type = 'Emergency' THEN TRUE ELSE FALSE END AS is_emergency,
    CASE WHEN e.encounter_type = 'Inpatient' THEN TRUE ELSE FALSE END AS is_inpatient,
    CASE WHEN e.duration_minutes > 1440     THEN TRUE ELSE FALSE END  AS is_extended_stay,
    CURRENT_TIMESTAMP()                     AS _fact_created_at

FROM encounters e
LEFT JOIN CLINICAL_WAREHOUSE.GOLD.dim_patient   p  ON e.patient_id  = p.patient_natural_key
LEFT JOIN CLINICAL_WAREHOUSE.GOLD.dim_provider  pv ON e.provider_id = pv.provider_natural_key
LEFT JOIN CLINICAL_WAREHOUSE.GOLD.dim_payer     py ON e.payer_id    = py.payer_natural_key
LEFT JOIN CLINICAL_WAREHOUSE.GOLD.dim_condition c  ON e.reason_code = c.condition_natural_key
LEFT JOIN CLINICAL_WAREHOUSE.GOLD.dim_date      d
    ON TO_NUMBER(TO_CHAR(e.encounter_date, 'YYYYMMDD')) = d.date_sk
    )
;


  
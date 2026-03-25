
  create or replace   view CLINICAL_WAREHOUSE.SILVER_STAGING.stg_providers
  
  
  
  
  as (
    

SELECT
    "id"                                                  AS provider_id,
    "organization"                                        AS organization_id,
    NULLIF(TRIM("name"), '')                              AS provider_name,
    UPPER(NULLIF(TRIM("gender"), ''))                     AS gender,
    NULLIF(TRIM("speciality"), '')                        AS specialty,
    UPPER(NULLIF(TRIM("state"), ''))                      AS state,
    NULLIF(TRIM("city"), '')                              AS city,
    NULLIF(TRIM("zip"), '')                               AS zip_code,
    TRY_CAST("utilization" AS INTEGER)                    AS encounter_utilization,
    "_fivetran_synced"                                    AS _fivetran_synced
FROM CLINICAL_WAREHOUSE.BRONZE.PROVIDERS
WHERE "id" IS NOT NULL
  );


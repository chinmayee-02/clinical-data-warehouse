

SELECT
    "id"                                                  AS patient_id,
    NULLIF(TRIM("first"), '')                              AS patient_first_name,
    NULLIF(TRIM("last"), '')                              AS patient_last_name,
    NULLIF(TRIM("prefix"), '')                            AS name_prefix,
    NULLIF(TRIM("ssn"), '')                               AS ssn,
    TRY_TO_DATE("birthdate", 'YYYY-MM-DD')                AS birthdate,
    TRY_TO_DATE("deathdate", 'YYYY-MM-DD')                AS deathdate,
    CASE WHEN "deathdate" IS NOT NULL THEN FALSE ELSE TRUE END AS is_alive,
    NULLIF(TRIM("marital"), '')                           AS marital_status,
    NULLIF(TRIM("race"), '')                              AS race,
    NULLIF(TRIM("ethnicity"), '')                         AS ethnicity,
    UPPER(NULLIF(TRIM("gender"), ''))                     AS gender,
    NULLIF(TRIM("address"), '')                           AS address,
    NULLIF(TRIM("city"), '')                              AS city,
    UPPER(NULLIF(TRIM("state"), ''))                      AS state,
    NULLIF(TRIM("zip"), '')                               AS zip_code,
    NULLIF(TRIM("county"), '')                            AS county,
    TRY_CAST("healthcare_expenses" AS FLOAT)              AS healthcare_expenses_usd,
    TRY_CAST("healthcare_coverage" AS FLOAT)              AS healthcare_coverage_usd,
    DATEDIFF('year', TRY_TO_DATE("birthdate",'YYYY-MM-DD'), CURRENT_DATE()) AS age_years,
    CASE
        WHEN DATEDIFF('year',TRY_TO_DATE("birthdate",'YYYY-MM-DD'),CURRENT_DATE()) < 18  THEN 'Pediatric (0-17)'
        WHEN DATEDIFF('year',TRY_TO_DATE("birthdate",'YYYY-MM-DD'),CURRENT_DATE()) < 40  THEN 'Young Adult (18-39)'
        WHEN DATEDIFF('year',TRY_TO_DATE("birthdate",'YYYY-MM-DD'),CURRENT_DATE()) < 65  THEN 'Middle Age (40-64)'
        ELSE 'Senior (65+)'
    END                                                   AS age_group,
    "_fivetran_synced"                                    AS _fivetran_synced
FROM CLINICAL_WAREHOUSE.BRONZE.PATIENTS
WHERE "id" IS NOT NULL
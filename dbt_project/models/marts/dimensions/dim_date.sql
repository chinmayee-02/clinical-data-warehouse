{{ config(materialized='table', schema='GOLD', tags=['gold','dimension']) }}

WITH dates AS (
    SELECT DISTINCT encounter_date AS full_date
    FROM {{ ref('stg_encounters') }}
    WHERE encounter_date IS NOT NULL
),
with_sk AS (
    SELECT
        TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD'))   AS date_sk,
        full_date,
        YEAR(full_date)                             AS year,
        QUARTER(full_date)                          AS quarter,
        MONTH(full_date)                            AS month_num,
        MONTHNAME(full_date)                        AS month_name,
        DAY(full_date)                              AS day_of_month,
        DAYNAME(full_date)                          AS day_name,
        WEEKOFYEAR(full_date)                       AS week_of_year,
        CASE DAYNAME(full_date)
            WHEN 'Saturday' THEN FALSE
            WHEN 'Sunday'   THEN FALSE
            ELSE TRUE
        END                                         AS is_weekday,
        TO_CHAR(full_date, 'YYYY-MM')               AS year_month
    FROM dates
)
SELECT -1 AS date_sk, NULL::DATE AS full_date, -1 AS year, -1 AS quarter,
    -1 AS month_num, 'Unknown' AS month_name, -1 AS day_of_month,
    'Unknown' AS day_name, -1 AS week_of_year, NULL AS is_weekday, 'Unknown' AS year_month
UNION ALL
SELECT * FROM with_sk

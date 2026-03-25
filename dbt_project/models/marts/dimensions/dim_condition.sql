{{ config(materialized='table', schema='GOLD', tags=['gold','dimension']) }}

WITH conditions AS (
    SELECT DISTINCT condition_code, condition_description, icd10_chapter
    FROM {{ ref('stg_conditions') }}
    WHERE condition_code IS NOT NULL
),
with_sk AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY condition_code)  AS condition_sk,
        condition_code                               AS condition_natural_key,
        condition_code,
        condition_description,
        icd10_chapter,
        CASE icd10_chapter
            WHEN 'A' THEN 'Infectious Diseases'
            WHEN 'B' THEN 'Infectious Diseases'
            WHEN 'C' THEN 'Neoplasms'
            WHEN 'D' THEN 'Blood Disorders'
            WHEN 'E' THEN 'Endocrine/Metabolic'
            WHEN 'F' THEN 'Mental Health'
            WHEN 'G' THEN 'Nervous System'
            WHEN 'I' THEN 'Circulatory System'
            WHEN 'J' THEN 'Respiratory System'
            WHEN 'K' THEN 'Digestive System'
            WHEN 'M' THEN 'Musculoskeletal'
            WHEN 'N' THEN 'Genitourinary'
            WHEN 'Z' THEN 'Health Status Factors'
            ELSE 'Other'
        END                                          AS icd10_chapter_name,
        CASE
            WHEN LOWER(condition_description) LIKE '%diabetes%'     THEN TRUE
            WHEN LOWER(condition_description) LIKE '%hypertension%' THEN TRUE
            WHEN LOWER(condition_description) LIKE '%asthma%'       THEN TRUE
            WHEN LOWER(condition_description) LIKE '%heart failure%' THEN TRUE
            WHEN LOWER(condition_description) LIKE '%depression%'   THEN TRUE
            WHEN LOWER(condition_description) LIKE '%obesity%'      THEN TRUE
            ELSE FALSE
        END                                          AS is_chronic_condition
    FROM conditions
)
SELECT -1 AS condition_sk, 'UNKNOWN' AS condition_natural_key,
    'Unknown' AS condition_code, 'Unknown' AS condition_description,
    'Unknown' AS icd10_chapter, 'Unknown' AS icd10_chapter_name,
    FALSE AS is_chronic_condition
UNION ALL
SELECT * FROM with_sk

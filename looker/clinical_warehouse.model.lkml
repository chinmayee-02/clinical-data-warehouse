# =============================================================================
# clinical_warehouse.model.lkml
# =============================================================================
# LookML Model: Clinical Data Warehouse
#
# This file defines:
#   1. The Snowflake database connection
#   2. All Explores (the query entry points Looker users see)
#   3. Explore-level joins between fact and dimension tables
#
# What is LookML?
# LookML is Looker's modeling layer — you define dimensions (descriptive
# attributes) and measures (aggregations) once here, and they're reusable
# across every report, dashboard, and API call. This is the key difference
# from Power BI: business logic lives in version-controlled code, not in
# report files.

connection: "clinical_snowflake"
# Connection configured in Looker Admin → Connections:
#   Host:     your_account.snowflakecomputing.com
#   Database: CLINICAL_WAREHOUSE
#   Schema:   GOLD
#   Username: CLINICAL_ANALYST_USER
#   Role:     CLINICAL_ANALYST_ROLE  ← enforces PHI masking

# Include all view files from the views/ directory
include: "/views/*.view.lkml"
include: "/dashboards/*.dashboard.lookml"

# =============================================================================
# EXPLORE: Clinical Encounters
# =============================================================================
# The primary explore — all clinical operations analytics starts here
# Users can slice by patient demographics, provider, payer, condition, time

explore: fact_encounter {
  label:       "Clinical Encounters"
  description: "Analyze patient encounters — costs, utilization, outcomes"
  group_label: "Clinical Analytics"

  # Patient dimension join
  join: dim_patient {
    type:         left_outer
    relationship: many_to_one          # Many encounters per patient
    sql_on: ${fact_encounter.patient_sk} = ${dim_patient.patient_sk} ;;
  }

  # Provider dimension join
  join: dim_provider {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_encounter.provider_sk} = ${dim_provider.provider_sk} ;;
  }

  # Payer dimension join
  join: dim_payer {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_encounter.payer_sk} = ${dim_payer.payer_sk} ;;
  }

  # Primary diagnosis condition
  join: dim_condition {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_encounter.primary_condition_sk} = ${dim_condition.condition_sk} ;;
  }

  # Date dimension join
  join: dim_date {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_encounter.date_sk} = ${dim_date.date_sk} ;;
  }
}

# =============================================================================
# EXPLORE: Medication Orders
# =============================================================================

explore: fact_medication_order {
  label:       "Medication Orders"
  description: "Analyze prescriptions — costs, active medications, payer coverage"
  group_label: "Clinical Analytics"

  join: dim_patient {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_medication_order.patient_sk} = ${dim_patient.patient_sk} ;;
  }

  join: dim_payer {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_medication_order.payer_sk} = ${dim_payer.payer_sk} ;;
  }

  join: dim_condition {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_medication_order.reason_condition_sk} = ${dim_condition.condition_sk} ;;
    fields: [dim_condition.condition_code, dim_condition.condition_description,
             dim_condition.icd10_chapter_name, dim_condition.is_chronic_condition]
  }

  join: dim_date {
    from:         dim_date
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_medication_order.start_date_sk} = ${dim_date.date_sk} ;;
  }
}

# =============================================================================
# EXPLORE: Population Health
# =============================================================================
# Patient-centric view — good for cohort analysis and population health mgmt

explore: dim_patient {
  label:       "Patient Population"
  description: "Analyze patient demographics, chronic conditions, and health outcomes"
  group_label: "Population Health"

  join: fact_encounter {
    type:         left_outer
    relationship: one_to_many
    sql_on: ${dim_patient.patient_sk} = ${fact_encounter.patient_sk} ;;
  }

  join: dim_payer {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_encounter.payer_sk} = ${dim_payer.payer_sk} ;;
  }

  join: dim_condition {
    type:         left_outer
    relationship: many_to_one
    sql_on: ${fact_encounter.primary_condition_sk} = ${dim_condition.condition_sk} ;;
  }
}

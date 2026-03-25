# =============================================================================
# dim_patient.view.lkml
# =============================================================================
# Patient dimension — PHI columns noted, Snowflake masking handles access

view: dim_patient {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.DIM_PATIENT ;;

  dimension: patient_sk {
    primary_key: yes
    type:        number
    sql:         ${TABLE}.patient_sk ;;
    hidden:      yes
  }

  dimension: patient_natural_key {
    type:        string
    sql:         ${TABLE}.patient_natural_key ;;
    label:       "Patient UUID"
    group_label: "Patient Identity"
    tags:        ["phi"]
  }

  # PHI dimensions — Snowflake masking policy returns [REDACTED] for ANALYST_ROLE
  dimension: patient_first_name {
    type:        string
    sql:         ${TABLE}.patient_first_name ;;
    label:       "First Name (PHI)"
    group_label: "Patient Identity"
    tags:        ["phi"]
  }

  dimension: patient_last_name {
    type:        string
    sql:         ${TABLE}.patient_last_name ;;
    label:       "Last Name (PHI)"
    group_label: "Patient Identity"
    tags:        ["phi"]
  }

  dimension: full_name {
    type:        string
    sql:         ${TABLE}.patient_first_name || ' ' || ${TABLE}.patient_last_name ;;
    label:       "Full Name (PHI)"
    group_label: "Patient Identity"
    tags:        ["phi"]
  }

  dimension_group: birthdate {
    type:        time
    timeframes:  [date, year]
    sql:         ${TABLE}.birthdate ;;
    label:       "Birthdate (PHI)"
    group_label: "Patient Identity"
    datatype:    date
    tags:        ["phi"]
  }

  # Non-PHI demographics — safe for all analysts
  dimension: gender {
    type:        string
    sql:         ${TABLE}.gender ;;
    label:       "Gender"
    group_label: "Demographics"
  }

  dimension: race {
    type:        string
    sql:         ${TABLE}.race ;;
    label:       "Race"
    group_label: "Demographics"
  }

  dimension: ethnicity {
    type:        string
    sql:         ${TABLE}.ethnicity ;;
    label:       "Ethnicity"
    group_label: "Demographics"
  }

  dimension: age_group {
    type:        string
    sql:         ${TABLE}.age_group ;;
    label:       "Age Group"
    group_label: "Demographics"
    description: "Pediatric (0-17) | Young Adult (18-39) | Middle Age (40-64) | Senior (65+)"
  }

  dimension: age_years {
    type:        number
    sql:         ${TABLE}.age_years ;;
    label:       "Age (years)"
    group_label: "Demographics"
  }

  dimension: state {
    type:        string
    sql:         ${TABLE}.state ;;
    label:       "State"
    group_label: "Location"
    map_layer_name: us_states
  }

  dimension: is_alive {
    type:        yesno
    sql:         ${TABLE}.is_alive ;;
    label:       "Is Alive?"
    group_label: "Demographics"
  }

  # Measures
  measure: count {
    type:  count
    label: "# Patients"
    drill_fields: [patient_natural_key, gender, age_group, state]
  }

  measure: pct_senior {
    type:        number
    label:       "% Senior Patients (65+)"
    sql:
      COUNT(CASE WHEN ${TABLE}.age_group = 'Senior (65+)' THEN 1 END)
      / NULLIF(COUNT(*), 0) ;;
    value_format: "0.0%"
    group_label: "Population Metrics"
  }
}


# =============================================================================
# dim_provider.view.lkml
# =============================================================================

view: dim_provider {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.DIM_PROVIDER ;;

  dimension: provider_sk {
    primary_key: yes
    type:        number
    sql:         ${TABLE}.provider_sk ;;
    hidden:      yes
  }

  dimension: provider_name {
    type:        string
    sql:         ${TABLE}.provider_name ;;
    label:       "Provider Name"
    group_label: "Provider Details"
  }

  dimension: specialty {
    type:        string
    sql:         ${TABLE}.specialty ;;
    label:       "Specialty"
    group_label: "Provider Details"
  }

  dimension: specialty_group {
    type:        string
    sql:         ${TABLE}.specialty_group ;;
    label:       "Specialty Group"
    group_label: "Provider Details"
    description: "Cardiology | General Practice | Emergency Medicine | Pediatrics | etc."
  }

  dimension: state {
    type:        string
    sql:         ${TABLE}.state ;;
    label:       "Provider State"
    group_label: "Location"
  }

  dimension: gender {
    type:        string
    sql:         ${TABLE}.gender ;;
    label:       "Provider Gender"
    group_label: "Provider Details"
  }

  measure: count {
    type:  count
    label: "# Providers"
  }

  measure: avg_utilization {
    type:        average
    sql:         ${TABLE}.encounter_utilization ;;
    label:       "Avg Encounter Utilization"
    value_format: "0"
    group_label: "Utilization"
  }
}


# =============================================================================
# dim_condition.view.lkml
# =============================================================================

view: dim_condition {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.DIM_CONDITION ;;

  dimension: condition_sk {
    primary_key: yes
    type:        number
    sql:         ${TABLE}.condition_sk ;;
    hidden:      yes
  }

  dimension: condition_code {
    type:        string
    sql:         ${TABLE}.condition_code ;;
    label:       "ICD-10 Code"
    group_label: "Condition"
  }

  dimension: condition_description {
    type:        string
    sql:         ${TABLE}.condition_description ;;
    label:       "Condition"
    group_label: "Condition"
    description: "Clinical description of the ICD-10 diagnosis code"
  }

  dimension: icd10_chapter_name {
    type:        string
    sql:         ${TABLE}.icd10_chapter_name ;;
    label:       "Disease Category (ICD-10)"
    group_label: "Condition"
  }

  dimension: is_chronic_condition {
    type:        yesno
    sql:         ${TABLE}.is_chronic_condition ;;
    label:       "Is Chronic Condition?"
    group_label: "Condition"
    description: "Diabetes, Hypertension, Asthma, Heart Failure, Depression, etc."
  }

  measure: count {
    type:  count
    label: "# Distinct Conditions"
  }
}


# =============================================================================
# dim_payer.view.lkml
# =============================================================================

view: dim_payer {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.DIM_PAYER ;;

  dimension: payer_sk {
    primary_key: yes
    type:        number
    sql:         ${TABLE}.payer_sk ;;
    hidden:      yes
  }

  dimension: payer_name {
    type:        string
    sql:         ${TABLE}.payer_name ;;
    label:       "Payer Name"
    group_label: "Payer"
  }

  dimension: payer_type {
    type:        string
    sql:         ${TABLE}.payer_type ;;
    label:       "Payer Type"
    group_label: "Payer"
    description: "Medicare | Medicaid | Commercial | Uninsured"
  }

  dimension: coverage_rate_pct {
    type:        number
    sql:         ${TABLE}.coverage_rate_pct ;;
    label:       "Coverage Rate (%)"
    group_label: "Payer Stats"
    value_format: "0.0"
  }

  measure: count {
    type:  count
    label: "# Payers"
  }

  measure: avg_member_months {
    type:        average
    sql:         ${TABLE}.member_months ;;
    label:       "Avg Member Months"
    value_format: "0,0"
    group_label: "Payer Stats"
  }
}


# =============================================================================
# dim_date.view.lkml
# =============================================================================

view: dim_date {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.DIM_DATE ;;

  dimension: date_sk {
    primary_key: yes
    type:        number
    sql:         ${TABLE}.date_sk ;;
    hidden:      yes
  }

  dimension: full_date {
    type:        date
    sql:         ${TABLE}.full_date ;;
    label:       "Date"
    group_label: "Date"
  }

  dimension: year {
    type:        number
    sql:         ${TABLE}.year ;;
    label:       "Year"
    group_label: "Date"
  }

  dimension: month_name {
    type:        string
    sql:         ${TABLE}.month_name ;;
    label:       "Month"
    group_label: "Date"
    order_by_field: month_num
  }

  dimension: month_num {
    type:        number
    sql:         ${TABLE}.month_num ;;
    hidden:      yes
  }

  dimension: fiscal_quarter_label {
    type:        string
    sql:         ${TABLE}.fiscal_quarter_label ;;
    label:       "Quarter"
    group_label: "Date"
  }

  dimension: year_month {
    type:        string
    sql:         ${TABLE}.year_month ;;
    label:       "Year-Month"
    group_label: "Date"
  }

  dimension: is_weekday {
    type:        yesno
    sql:         ${TABLE}.is_weekday ;;
    label:       "Is Weekday?"
    group_label: "Date"
  }
}


# =============================================================================
# fact_medication_order.view.lkml
# =============================================================================

view: fact_medication_order {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.FACT_MEDICATION_ORDER ;;

  dimension: patient_sk  { type: number; sql: ${TABLE}.patient_sk  ;; hidden: yes }
  dimension: payer_sk    { type: number; sql: ${TABLE}.payer_sk    ;; hidden: yes }
  dimension: reason_condition_sk { type: number; sql: ${TABLE}.reason_condition_sk ;; hidden: yes }
  dimension: start_date_sk { type: number; sql: ${TABLE}.start_date_sk ;; hidden: yes }

  dimension: medication_code {
    type:        string
    sql:         ${TABLE}.medication_code ;;
    label:       "Medication Code"
    group_label: "Medication"
  }

  dimension: medication_name {
    type:        string
    sql:         ${TABLE}.medication_name ;;
    label:       "Medication Name"
    group_label: "Medication"
  }

  dimension: is_active {
    type:        yesno
    sql:         ${TABLE}.is_active ;;
    label:       "Is Active Prescription?"
    group_label: "Medication"
  }

  dimension_group: prescription_start {
    type:       time
    timeframes: [date, month, quarter, year]
    sql:        ${TABLE}.prescription_start_date ;;
    datatype:   date
    label:      "Prescription Start"
  }

  measure: count {
    type:  count
    label: "# Prescriptions"
  }

  measure: count_active {
    type:    count
    filters: [is_active: "yes"]
    label:   "# Active Prescriptions"
  }

  measure: total_medication_cost {
    type:        sum
    sql:         ${TABLE}.total_cost_usd ;;
    label:       "Total Medication Cost"
    value_format: "$#,##0"
    group_label: "Financials"
  }

  measure: avg_days_on_medication {
    type:        average
    sql:         ${TABLE}.days_on_medication ;;
    label:       "Avg Days on Medication"
    value_format: "0"
    group_label: "Utilization"
  }

  measure: total_patient_oop {
    type:        sum
    sql:         ${TABLE}.patient_oop_usd ;;
    label:       "Total Patient Out-of-Pocket (Rx)"
    value_format: "$#,##0"
    group_label: "Financials"
  }
}

# =============================================================================
# fact_encounter.view.lkml
# =============================================================================
# The central view — all clinical encounter dimensions and measures
#
# Key LookML concepts demonstrated:
#   dimension:  a descriptive attribute (maps to SELECT column)
#   measure:    an aggregation (maps to SELECT COUNT/SUM/AVG)
#   type:       the data type (string, number, date, yesno)
#   sql:        the underlying SQL expression
#   label:      what Looker users see in the UI
#   group_label: organizes dimensions/measures into sections

view: fact_encounter {
  sql_table_name: CLINICAL_WAREHOUSE.GOLD.FACT_ENCOUNTER ;;

  # ── Primary key ─────────────────────────────────────────────────────────────
  dimension: encounter_id {
    primary_key: yes
    type:        string
    sql:         ${TABLE}.encounter_id ;;
    label:       "Encounter ID"
    description: "Unique identifier for each clinical encounter"
  }

  # ── Foreign keys (hidden — used for joins, not displayed to users) ───────────
  dimension: patient_sk {
    type:   number
    sql:    ${TABLE}.patient_sk ;;
    hidden: yes
  }

  dimension: provider_sk {
    type:   number
    sql:    ${TABLE}.provider_sk ;;
    hidden: yes
  }

  dimension: payer_sk {
    type:   number
    sql:    ${TABLE}.payer_sk ;;
    hidden: yes
  }

  dimension: primary_condition_sk {
    type:   number
    sql:    ${TABLE}.primary_condition_sk ;;
    hidden: yes
  }

  dimension: date_sk {
    type:   number
    sql:    ${TABLE}.date_sk ;;
    hidden: yes
  }

  # ── Encounter classification ─────────────────────────────────────────────────
  dimension: encounter_type {
    type:        string
    sql:         ${TABLE}.encounter_type ;;
    label:       "Encounter Type"
    group_label: "Encounter Details"
    description: "Clinical classification: Inpatient, Outpatient, Emergency, etc."
  }

  dimension: encounter_class {
    type:        string
    sql:         ${TABLE}.encounter_class ;;
    label:       "Encounter Class (Raw)"
    group_label: "Encounter Details"
    hidden:      yes
  }

  dimension: encounter_description {
    type:        string
    sql:         ${TABLE}.encounter_description ;;
    label:       "Encounter Description"
    group_label: "Encounter Details"
  }

  # ── Date/time dimensions ─────────────────────────────────────────────────────
  dimension_group: encounter_start {
    type:        time
    timeframes:  [raw, date, week, month, quarter, year]
    sql:         ${TABLE}.encounter_start_ts ;;
    label:       "Encounter Start"
    group_label: "Time"
    datatype:    timestamp
  }

  dimension: duration_minutes {
    type:        number
    sql:         ${TABLE}.duration_minutes ;;
    label:       "Duration (minutes)"
    group_label: "Encounter Details"
  }

  dimension: duration_hours {
    type:        number
    sql:         ROUND(${TABLE}.duration_minutes / 60.0, 1) ;;
    label:       "Duration (hours)"
    group_label: "Encounter Details"
    value_format: "0.0"
  }

  # ── Financial dimensions ──────────────────────────────────────────────────────
  dimension: total_claim_cost_usd {
    type:        number
    sql:         ${TABLE}.total_claim_cost_usd ;;
    label:       "Total Claim Cost"
    group_label: "Financials"
    value_format: "$#,##0.00"
    hidden:      yes    # Use measures for aggregation — expose for row-level only
  }

  # ── Boolean flags ─────────────────────────────────────────────────────────────
  dimension: is_emergency {
    type:        yesno
    sql:         ${TABLE}.is_emergency ;;
    label:       "Is Emergency?"
    group_label: "Flags"
  }

  dimension: is_inpatient {
    type:        yesno
    sql:         ${TABLE}.is_inpatient ;;
    label:       "Is Inpatient?"
    group_label: "Flags"
  }

  dimension: is_extended_stay {
    type:        yesno
    sql:         ${TABLE}.is_extended_stay ;;
    label:       "Is Extended Stay (24h+)?"
    group_label: "Flags"
  }

  # ── Cost tier dimension (for bucketing in charts) ─────────────────────────────
  dimension: cost_tier {
    type: string
    sql:
      CASE
        WHEN ${TABLE}.total_claim_cost_usd < 100    THEN '< $100'
        WHEN ${TABLE}.total_claim_cost_usd < 500    THEN '$100–$499'
        WHEN ${TABLE}.total_claim_cost_usd < 1000   THEN '$500–$999'
        WHEN ${TABLE}.total_claim_cost_usd < 5000   THEN '$1K–$4.9K'
        WHEN ${TABLE}.total_claim_cost_usd < 10000  THEN '$5K–$9.9K'
        ELSE '$10K+'
      END ;;
    label:       "Cost Tier"
    group_label: "Financials"
    order_by_field: total_claim_cost_usd
  }

  # =============================================================================
  # MEASURES — the aggregations Looker users see on dashboards
  # =============================================================================

  measure: count {
    type:        count
    label:       "# Encounters"
    description: "Total number of clinical encounters"
    drill_fields: [encounter_id, encounter_type, dim_patient.age_group, total_claim_cost_usd]
  }

  measure: count_emergency {
    type:        count
    label:       "# Emergency Encounters"
    filters:     [is_emergency: "yes"]
    group_label: "Encounter Counts"
  }

  measure: count_inpatient {
    type:        count
    label:       "# Inpatient Encounters"
    filters:     [is_inpatient: "yes"]
    group_label: "Encounter Counts"
  }

  measure: emergency_rate {
    type:        number
    label:       "Emergency Rate"
    description: "% of encounters that are emergency visits"
    sql:         ${count_emergency} / NULLIF(${count}, 0) ;;
    value_format: "0.0%"
    group_label: "Encounter Counts"
  }

  measure: total_cost {
    type:        sum
    sql:         ${TABLE}.total_claim_cost_usd ;;
    label:       "Total Claim Cost"
    value_format: "$#,##0"
    group_label: "Financials"
    drill_fields: [encounter_id, encounter_type, dim_patient.age_group, total_claim_cost_usd]
  }

  measure: avg_cost_per_encounter {
    type:        average
    sql:         ${TABLE}.total_claim_cost_usd ;;
    label:       "Avg Cost per Encounter"
    value_format: "$#,##0.00"
    group_label: "Financials"
  }

  measure: total_payer_coverage {
    type:        sum
    sql:         ${TABLE}.payer_coverage_usd ;;
    label:       "Total Payer Coverage"
    value_format: "$#,##0"
    group_label: "Financials"
  }

  measure: total_patient_oop {
    type:        sum
    sql:         ${TABLE}.patient_oop_cost_usd ;;
    label:       "Total Patient Out-of-Pocket"
    value_format: "$#,##0"
    group_label: "Financials"
  }

  measure: avg_payer_coverage_rate {
    type:        average
    sql:         ${TABLE}.payer_coverage_rate_pct ;;
    label:       "Avg Payer Coverage Rate"
    value_format: "0.0%"
    group_label: "Financials"
  }

  measure: avg_duration_minutes {
    type:        average
    sql:         ${TABLE}.duration_minutes ;;
    label:       "Avg Duration (minutes)"
    value_format: "0"
    group_label: "Utilization"
  }

  measure: avg_duration_hours {
    type:        average
    sql:         ${TABLE}.duration_minutes / 60.0 ;;
    label:       "Avg Duration (hours)"
    value_format: "0.0"
    group_label: "Utilization"
  }

  measure: count_unique_patients {
    type:        count_distinct
    sql:         ${TABLE}.patient_sk ;;
    label:       "# Unique Patients"
    group_label: "Utilization"
  }

  measure: encounters_per_patient {
    type:        number
    label:       "Avg Encounters per Patient"
    sql:         ${count} / NULLIF(${count_unique_patients}, 0) ;;
    value_format: "0.0"
    group_label: "Utilization"
    description: "Utilization metric — high value may indicate chronic conditions"
  }
}

# =============================================================================
# clinical_overview.dashboard.lookml
# =============================================================================
# Clinical Operations Dashboard
# Built entirely in LookML — version-controlled, reproducible
#
# To use: paste this file into your Looker project and it deploys automatically

- dashboard: clinical_operations_overview
  title: "Clinical Operations Overview"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "HIPAA-compliant clinical analytics — encounters, costs, utilization"
  refresh: 1 hour

  filters:
    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "90 days"
      allow_multiple_values: false
      required: false

    - name: encounter_type_filter
      title: "Encounter Type"
      type: field_filter
      default_value: ""
      allow_multiple_values: true
      required: false
      model: clinical_warehouse
      explore: fact_encounter
      field: fact_encounter.encounter_type

    - name: payer_type_filter
      title: "Payer Type"
      type: field_filter
      default_value: ""
      allow_multiple_values: true
      required: false
      model: clinical_warehouse
      explore: fact_encounter
      field: dim_payer.payer_type

  elements:

    # ── Row 1: KPI Cards ───────────────────────────────────────────────────────
    - title: "Total Encounters"
      name: kpi_total_encounters
      model: clinical_warehouse
      explore: fact_encounter
      type: single_value
      fields: [fact_encounter.count]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      value_format: "#,##0"
      row: 0
      col: 0
      width: 4
      height: 3

    - title: "Unique Patients"
      name: kpi_unique_patients
      model: clinical_warehouse
      explore: fact_encounter
      type: single_value
      fields: [fact_encounter.count_unique_patients]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      value_format: "#,##0"
      row: 0
      col: 4
      width: 4
      height: 3

    - title: "Total Claim Cost"
      name: kpi_total_cost
      model: clinical_warehouse
      explore: fact_encounter
      type: single_value
      fields: [fact_encounter.total_cost]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      value_format: "$#,##0"
      row: 0
      col: 8
      width: 4
      height: 3

    - title: "Avg Cost per Encounter"
      name: kpi_avg_cost
      model: clinical_warehouse
      explore: fact_encounter
      type: single_value
      fields: [fact_encounter.avg_cost_per_encounter]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      value_format: "$#,##0"
      row: 0
      col: 12
      width: 4
      height: 3

    - title: "Emergency Rate"
      name: kpi_emergency_rate
      model: clinical_warehouse
      explore: fact_encounter
      type: single_value
      fields: [fact_encounter.emergency_rate]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      value_format: "0.0%"
      row: 0
      col: 16
      width: 4
      height: 3

    - title: "Avg Payer Coverage"
      name: kpi_avg_coverage
      model: clinical_warehouse
      explore: fact_encounter
      type: single_value
      fields: [fact_encounter.avg_payer_coverage_rate]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      value_format: "0.0%"
      row: 0
      col: 20
      width: 4
      height: 3

    # ── Row 2: Encounter Trend ─────────────────────────────────────────────────
    - title: "Monthly Encounter Volume & Cost Trend"
      name: encounter_trend
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_line
      fields:
        - dim_date.year_month
        - fact_encounter.count
        - fact_encounter.total_cost
        - fact_encounter.avg_cost_per_encounter
      sorts: [dim_date.year_month asc]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      series_types:
        fact_encounter.total_cost: bar
        fact_encounter.count: line
        fact_encounter.avg_cost_per_encounter: line
      hidden_fields: []
      x_axis_label: "Month"
      row: 3
      col: 0
      width: 16
      height: 8

    # ── Row 2: Encounter Type Donut ────────────────────────────────────────────
    - title: "Encounters by Type"
      name: encounter_by_type
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_pie
      fields:
        - fact_encounter.encounter_type
        - fact_encounter.count
      sorts: [fact_encounter.count desc]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      row: 3
      col: 16
      width: 8
      height: 8

    # ── Row 3: Cost by Payer Type ──────────────────────────────────────────────
    - title: "Total Claim Cost by Payer Type"
      name: cost_by_payer
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_bar
      fields:
        - dim_payer.payer_type
        - fact_encounter.total_cost
        - fact_encounter.total_payer_coverage
        - fact_encounter.total_patient_oop
      sorts: [fact_encounter.total_cost desc]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      stacking: normal
      x_axis_label: "Payer Type"
      row: 11
      col: 0
      width: 12
      height: 8

    # ── Row 3: Top Conditions ──────────────────────────────────────────────────
    - title: "Top 10 Conditions by Encounter Volume"
      name: top_conditions
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_bar
      fields:
        - dim_condition.condition_description
        - fact_encounter.count
        - fact_encounter.avg_cost_per_encounter
      sorts: [fact_encounter.count desc]
      limit: 10
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      x_axis_label: "Condition"
      row: 11
      col: 12
      width: 12
      height: 8

    # ── Row 4: Age Group Distribution ─────────────────────────────────────────
    - title: "Encounters by Age Group"
      name: age_group_distribution
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_column
      fields:
        - dim_patient.age_group
        - fact_encounter.count
        - fact_encounter.avg_cost_per_encounter
        - fact_encounter.emergency_rate
      sorts: [dim_patient.age_group]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      row: 19
      col: 0
      width: 12
      height: 8

    # ── Row 4: Provider Specialty ──────────────────────────────────────────────
    - title: "Encounters by Provider Specialty"
      name: specialty_breakdown
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_column
      fields:
        - dim_provider.specialty_group
        - fact_encounter.count
        - fact_encounter.total_cost
      sorts: [fact_encounter.count desc]
      filters:
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      row: 19
      col: 12
      width: 12
      height: 8

    # ── Row 5: Chronic Condition Patients ─────────────────────────────────────
    - title: "Chronic Condition Patient Analysis"
      name: chronic_conditions
      model: clinical_warehouse
      explore: fact_encounter
      type: looker_bar
      fields:
        - dim_condition.condition_description
        - fact_encounter.count_unique_patients
        - fact_encounter.avg_cost_per_encounter
        - fact_encounter.encounters_per_patient
      filters:
        dim_condition.is_chronic_condition: "yes"
        fact_encounter.encounter_start_date: "{% date_start date_range %} to {% date_end date_range %}"
      sorts: [fact_encounter.count_unique_patients desc]
      limit: 10
      row: 27
      col: 0
      width: 24
      height: 8

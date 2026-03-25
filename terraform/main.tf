terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.70"
    }
  }
}

provider "snowflake" {
  account  = var.snowflake_account
  username = var.snowflake_username
  password = var.snowflake_password
  role     = "ACCOUNTADMIN"
}

variable "snowflake_account" {
  type = string
}

variable "snowflake_username" {
  type = string
}

variable "snowflake_password" {
  type      = string
  sensitive = true
}

# ─── Warehouse ────────────────────────────────────────────────────────────────
resource "snowflake_warehouse" "clinical_wh" {
  name           = "CLINICAL_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60
  auto_resume    = true
  comment        = "Clinical Data Warehouse — HIPAA-aligned"
}

# ─── Database ─────────────────────────────────────────────────────────────────
resource "snowflake_database" "clinical_db" {
  name    = "CLINICAL_WAREHOUSE"
  comment = "Synthea EHR Data — Kimball Star Schema — HIPAA-aligned"
}

# ─── Schemas ──────────────────────────────────────────────────────────────────
resource "snowflake_schema" "bronze" {
  database = snowflake_database.clinical_db.name
  name     = "BRONZE"
  comment  = "Fivetran raw sync — immutable after landing"
}

resource "snowflake_schema" "gold" {
  database = snowflake_database.clinical_db.name
  name     = "GOLD"
  comment  = "Kimball star schema — PHI masking applied"
}

# ─── Roles ────────────────────────────────────────────────────────────────────
resource "snowflake_role" "fivetran_role" {
  name    = "FIVETRAN_ROLE"
  comment = "Fivetran connector — Bronze write only"
}

resource "snowflake_role" "dbt_role" {
  name    = "DBT_ROLE"
  comment = "dbt — reads Bronze, writes Gold"
}

resource "snowflake_role" "analyst_role" {
  name    = "CLINICAL_ANALYST_ROLE"
  comment = "Analysts — Gold read-only, PHI masked"
}

resource "snowflake_role" "admin_role" {
  name    = "CLINICAL_ADMIN_ROLE"
  comment = "Authorized clinical staff — unmasked PHI"
}

# ─── Outputs ──────────────────────────────────────────────────────────────────
output "warehouse"     { value = snowflake_warehouse.clinical_wh.name }
output "database"      { value = snowflake_database.clinical_db.name }
output "bronze_schema" { value = snowflake_schema.bronze.name }
output "gold_schema"   { value = snowflake_schema.gold.name }
output "fivetran_role" { value = snowflake_role.fivetran_role.name }
output "analyst_role"  { value = snowflake_role.analyst_role.name }

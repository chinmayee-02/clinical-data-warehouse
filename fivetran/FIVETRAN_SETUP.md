# Fivetran Setup Guide — Step by Step

## What Fivetran Does in This Project

Fivetran is the **managed ingestion layer**. It connects your PostgreSQL EHR
source to Snowflake Bronze automatically — no Python ingestion code needed.
This is exactly how it works in enterprise: DE teams use Fivetran for
standard source connectors and focus engineering effort on transformation.

---

## Step 1: Create Fivetran Account

1. Go to https://fivetran.com → Start Free Trial
2. No credit card required for 14-day trial
3. You get 5 connectors free — more than enough

---

## Step 2: Create Snowflake Destination

1. In Fivetran UI → **Destinations** → **+ Add Destination**
2. Select: **Snowflake**
3. Fill in:
   ```
   Account:    your_account.snowflakecomputing.com
   Database:   CLINICAL_WAREHOUSE
   Schema:     BRONZE
   Username:   FIVETRAN_SERVICE_USER
   Password:   (create a user in Snowflake first — see below)
   Role:       FIVETRAN_ROLE
   Warehouse:  CLINICAL_WH
   ```
4. Click **Test Connection** → should show green

**Create the Fivetran Snowflake user first:**
```sql
-- Run in Snowflake as SYSADMIN
CREATE USER FIVETRAN_SERVICE_USER
    PASSWORD = 'strong_password_here'
    DEFAULT_ROLE = FIVETRAN_ROLE
    DEFAULT_WAREHOUSE = CLINICAL_WH;

GRANT ROLE FIVETRAN_ROLE TO USER FIVETRAN_SERVICE_USER;
```

---

## Step 3: Create PostgreSQL Source Connector

1. Fivetran UI → **Connectors** → **+ Add Connector**
2. Search for: **PostgreSQL**
3. Fill in:
   ```
   Host:           localhost (or your Postgres IP)
   Port:           5432
   Database:       ehr
   Schema:         ehr
   Username:       postgres
   Password:       clinical
   Connection:     Directly (not SSH tunnel for local)
   Update Method:  XMIN   ← use this if wal_level is not logical
   ```
4. **Schema Selection** → select all tables under `ehr` schema:
   - ✅ patients
   - ✅ encounters
   - ✅ conditions
   - ✅ medications
   - ✅ payers
   - ✅ providers
   - ✅ observations
   - ✅ procedures
   - ✅ allergies

5. Set **Sync Frequency**: 6 hours (360 minutes)
6. Click **Save & Test**

---

## Step 4: Trigger Initial Sync

1. Click **Sync Now** on your connector
2. Watch the sync progress in Fivetran UI
3. First sync: full table load (~2-5 min for Synthea data)
4. Subsequent syncs: incremental (only changed rows via XMIN)

---

## Step 5: Verify in Snowflake

```sql
-- Check tables landed in Bronze
SHOW TABLES IN SCHEMA CLINICAL_WAREHOUSE.BRONZE;

-- Verify row counts
SELECT 'patients'   AS tbl, COUNT(*) FROM CLINICAL_WAREHOUSE.BRONZE.PATIENTS   UNION ALL
SELECT 'encounters'        , COUNT(*) FROM CLINICAL_WAREHOUSE.BRONZE.ENCOUNTERS UNION ALL
SELECT 'conditions'        , COUNT(*) FROM CLINICAL_WAREHOUSE.BRONZE.CONDITIONS UNION ALL
SELECT 'medications'       , COUNT(*) FROM CLINICAL_WAREHOUSE.BRONZE.MEDICATIONS;

-- Check Fivetran audit columns exist
SELECT _fivetran_synced, _fivetran_deleted
FROM CLINICAL_WAREHOUSE.BRONZE.PATIENTS LIMIT 5;
```

---

## XMIN vs LOG_BASED (Interview Talking Point)

> "Fivetran supports two update detection methods for PostgreSQL.
> XMIN uses PostgreSQL's internal transaction ID to detect changed rows —
> simpler setup, no wal_level changes needed.
> LOG_BASED uses WAL (Write-Ahead Log) CDC for true change data capture —
> lower latency, captures deletes, but requires wal_level=logical.
> For this portfolio I used XMIN for simplicity. In production at a health
> system I'd use LOG_BASED to capture row deletes (patient record corrections)
> and reduce Snowflake compute costs on large tables."

---

## What Fivetran Adds Automatically

Every synced table gets these audit columns — no code needed:

| Column | Type | Meaning |
|--------|------|---------|
| `_fivetran_synced` | TIMESTAMP | Last time Fivetran synced this row |
| `_fivetran_deleted` | BOOLEAN | True if row was deleted in source |
| `_fivetran_id` | VARCHAR | Fivetran internal row ID (for tables without PK) |

Your dbt staging models use `_fivetran_deleted = FALSE` to filter soft deletes.

---

## Troubleshooting

**"Connection refused" on PostgreSQL:**
```bash
# Make sure PostgreSQL Docker container is running
docker ps | grep postgres
# If not: docker run -d -e POSTGRES_PASSWORD=clinical -e POSTGRES_DB=ehr -p 5432:5432 postgres:15
```

**"Permission denied" on Snowflake:**
```sql
-- Verify FIVETRAN_ROLE has correct grants
SHOW GRANTS TO ROLE FIVETRAN_ROLE;
```

**Fivetran can't reach localhost:**
Use ngrok to expose local Postgres: `ngrok tcp 5432`
Then use the ngrok hostname in Fivetran connector config.

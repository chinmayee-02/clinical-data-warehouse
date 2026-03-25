# 🏥 Clinical Data Warehouse
### Portfolio Project — Fivetran · Terraform · Snowflake · dbt · Looker Studio

**Stack:** Terraform · Fivetran · Snowflake · Python · dbt · Looker Studio  
**Domain:** Healthcare / HIPAA-aligned · Synthea synthetic EHR data  
**Patterns:** Kimball Star Schema · Medallion Architecture · Incremental Loading · RBAC

---

## Live Dashboard
👉 [View Clinical Operations Dashboard](https://lookerstudio.google.com/s/hJqiBAxYFUQ)

![Dashboard Preview](https://github.com/user-attachments/assets/d56ecd10-39f7-45b5-bf8c-7d3d2d192b57)

---

## What This Project Does

End-to-end clinical data warehouse built on synthetic EHR data (1,171 patients,
53,346 encounters, 447,022 total records). Demonstrates the full modern data stack
from managed ingestion to governed analytics.

## Key Numbers
| Metric | Value |
|--------|-------|
| Total patients | 1,171 |
| Total encounters | 53,346 |
| Total records ingested | 447,022 |
| dbt models | 12 (6 staging + 5 dims + 1 fact) |
| Snowflake schemas | 2 (BRONZE + GOLD) |
| Roles provisioned | 4 (least-privilege per layer) |

## HIPAA Design Decisions
| Control | Implementation |
|---------|----------------|
| Role-Based Access Control | 4 roles provisioned via Terraform (FIVETRAN, DBT, ANALYST, ADMIN) |
| PHI column tagging | dbt schema.yml tags all PHI columns (name, SSN, birthdate, address) |
| Least-privilege access | ANALYST_ROLE reads GOLD only, cannot touch BRONZE |
| Audit columns | Fivetran `_fivetran_synced` + `_fivetran_deleted` on all Bronze tables |
| Infrastructure as code | All roles, schemas, grants provisioned via Terraform — auditable + reproducible |

> Note: Dynamic data masking requires Snowflake Enterprise edition.
> Architecture is designed for masking — policies would be applied in production.

## Built With Claude AI
Developed using Claude AI (Anthropic) as a development partner for scaffolding
Terraform configs, dbt models, and dashboard queries — all architectural decisions
owned by the developer.












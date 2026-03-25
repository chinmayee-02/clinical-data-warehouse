import os
import pandas as pd
import psycopg2
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

NEON_CONN = "postgresql://neondb_owner:npg_5HoIZMfEzLt2@ep-mute-credit-an0jimi1-pooler.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require"

DATA_DIR = Path("./data/synthea")

TABLES = [
    "patients", "encounters", "conditions", "medications",
    "payers", "providers", "observations", "procedures", "allergies"
]

def get_conn():
    return psycopg2.connect(NEON_CONN)

def load_table(conn, table_name):
    csv_path = DATA_DIR / f"{table_name}.csv"
    if not csv_path.exists():
        log.warning(f"{csv_path} not found — skipping")
        return 0

    df = pd.read_csv(csv_path, low_memory=False)
    cols = [c.strip().lower().replace(" ", "_").replace(".", "_") for c in df.columns]
    df.columns = cols
    df = df.fillna("").astype(str)

    col_defs = ", ".join([f'"{c}" TEXT' for c in cols])
    col_defs += ', "_fivetran_synced" TIMESTAMPTZ DEFAULT NOW()'
    col_defs += ', "_fivetran_deleted" BOOLEAN DEFAULT FALSE'

    with conn.cursor() as cur:
        cur.execute(f'DROP TABLE IF EXISTS "{table_name}"')
        cur.execute(f'CREATE TABLE "{table_name}" ({col_defs})')
    conn.commit()

    rows = [tuple(r) for r in df.itertuples(index=False)]
    placeholders = ", ".join(["%s"] * len(cols))
    col_str = ", ".join([f'"{c}"' for c in cols])

    batch_size = 500
    total = 0
    with conn.cursor() as cur:
        for i in range(0, len(rows), batch_size):
            batch = rows[i:i+batch_size]
            cur.executemany(
                f'INSERT INTO "{table_name}" ({col_str}) VALUES ({placeholders})',
                batch
            )
            total += len(batch)
    conn.commit()
    log.info(f"  ✅ {table_name}: {total:,} rows")
    return total

if __name__ == "__main__":
    log.info("=== Loading Synthea data into Neon PostgreSQL ===")
    conn = get_conn()
    total = 0
    for table in TABLES:
        total += load_table(conn, table)
    conn.close()
    log.info(f"\n✅ Total rows loaded: {total:,}")
    log.info("Next: configure Fivetran with Neon connection details")

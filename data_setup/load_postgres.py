"""
DATA SETUP — Load Synthea Synthetic EHR Data into PostgreSQL
Dynamically creates tables based on actual CSV columns.
"""

import os
import requests
import zipfile
import logging
import pandas as pd
import psycopg2
from pathlib import Path
from io import BytesIO

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

PG_CONFIG = {
    "host":     os.environ.get("POSTGRES_HOST", "localhost"),
    "port":     int(os.environ.get("POSTGRES_PORT", 5432)),
    "dbname":   os.environ.get("POSTGRES_DB", "ehr"),
    "user":     os.environ.get("POSTGRES_USER", "postgres"),
    "password": os.environ.get("POSTGRES_PASSWORD", "clinical"),
}

SYNTHEA_DATA_URL = "https://synthetichealth.github.io/synthea-sample-data/downloads/synthea_sample_data_csv_apr2020.zip"
DATA_DIR = Path("./data/synthea")

SYNTHEA_TABLES = {
    "patients.csv":     "patients",
    "encounters.csv":   "encounters",
    "conditions.csv":   "conditions",
    "medications.csv":  "medications",
    "payers.csv":       "payers",
    "providers.csv":    "providers",
    "observations.csv": "observations",
    "procedures.csv":   "procedures",
    "allergies.csv":    "allergies",
}


def download_synthea_data():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    if list(DATA_DIR.glob("*.csv")):
        log.info(f"Synthea CSVs already present in {DATA_DIR} — skipping download")
        return

    log.info("Downloading Synthea sample dataset (~50MB)...")
    resp = requests.get(SYNTHEA_DATA_URL, timeout=120, stream=True)
    resp.raise_for_status()

    log.info("Extracting CSV files...")
    with zipfile.ZipFile(BytesIO(resp.content)) as z:
        for name in z.namelist():
            filename = Path(name).name
            if filename in SYNTHEA_TABLES:
                data = z.read(name)
                (DATA_DIR / filename).write_bytes(data)
                log.info(f"  Extracted: {filename}")

    log.info(f"Synthea data ready in {DATA_DIR}")


def get_conn():
    return psycopg2.connect(**PG_CONFIG)


def setup_schema(conn):
    with conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS ehr;")
    conn.commit()
    log.info("PostgreSQL schema 'ehr' ready")


def create_table_from_csv(conn, csv_path: Path, table_name: str):
    """Dynamically create table based on actual CSV columns — all VARCHAR."""
    df = pd.read_csv(csv_path, nrows=0)
    cols = [c.strip().lower().replace(" ", "_") for c in df.columns]

    col_defs = ",\n    ".join([f'"{c}" VARCHAR' for c in cols])
    col_defs += ',\n    _fivetran_synced TIMESTAMPTZ DEFAULT NOW()'
    col_defs += ',\n    _fivetran_deleted BOOLEAN DEFAULT FALSE'

    with conn.cursor() as cur:
        cur.execute(f"DROP TABLE IF EXISTS ehr.{table_name};")
        cur.execute(f"""
            CREATE TABLE ehr.{table_name} (
                {col_defs}
            );
        """)
    conn.commit()
    log.info(f"  Created table: ehr.{table_name} ({len(cols)} columns)")
    return cols


def load_table(conn, csv_path: Path, table_name: str, cols: list) -> int:
    """Load CSV into PostgreSQL using COPY."""
    col_str = ", ".join([f'"{c}"' for c in cols])
    copy_sql = f'COPY ehr.{table_name} ({col_str}) FROM STDIN WITH CSV'

    with conn.cursor() as cur, open(csv_path, 'r') as f:
        next(f)  # Skip header
        cur.copy_expert(copy_sql, f)
    conn.commit()

    with conn.cursor() as cur:
        cur.execute(f"SELECT COUNT(*) FROM ehr.{table_name}")
        count = cur.fetchone()[0]
    return count


if __name__ == "__main__":
    log.info("=== Synthea EHR Data Setup ===")

    download_synthea_data()

    log.info("Connecting to PostgreSQL...")
    conn = get_conn()
    setup_schema(conn)

    total = 0
    for csv_file, table_name in SYNTHEA_TABLES.items():
        csv_path = DATA_DIR / csv_file
        if not csv_path.exists():
            log.warning(f"  {csv_file} not found — skipping")
            continue

        log.info(f"Loading: {csv_file}")
        cols = create_table_from_csv(conn, csv_path, table_name)
        count = load_table(conn, csv_path, table_name, cols)
        log.info(f"  ✅ ehr.{table_name}: {count:,} rows")
        total += count

    conn.close()
    log.info(f"\n✅ Total rows loaded: {total:,}")
    log.info("Next step: Configure Fivetran connector")

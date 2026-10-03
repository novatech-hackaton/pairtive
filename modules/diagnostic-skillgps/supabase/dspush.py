"""Apply dsschema.sql then dsseed.sql to the Supabase Postgres database.

Reads SUPABASE_DB_URL from supabase/.env (never printed). Runs each SQL file as
one script. Safe to re-run: both scripts are idempotent. Prints a short summary
and final row counts, but never the connection string.
"""

from __future__ import annotations

import os
import sys

import psycopg

HERE = os.path.dirname(os.path.abspath(__file__))


def load_db_url() -> str:
    # Prefer an already-exported env var; else read supabase/.env.
    url = os.environ.get("SUPABASE_DB_URL", "").strip()
    if not url:
        env_path = os.path.join(HERE, ".env")
        if os.path.isfile(env_path):
            for line in open(env_path, "r", encoding="utf-8"):
                line = line.strip()
                if line.startswith("SUPABASE_DB_URL="):
                    url = line.split("=", 1)[1].strip()
                    break
    if not url or "your-ref" in url or "your-password" in url:
        print("ERROR: SUPABASE_DB_URL is not set to a real value in supabase/.env", file=sys.stderr)
        sys.exit(2)
    return url


def run_sql_file(conn, path: str, label: str) -> None:
    with open(path, "r", encoding="utf-8-sig") as f:
        sql = f.read()
    print(f"Running {label} ({len(sql)} chars)...")
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
    print(f"  {label}: OK")


def main() -> int:
    url = load_db_url()
    try:
        with psycopg.connect(url, connect_timeout=20) as conn:
            run_sql_file(conn, os.path.join(HERE, "dsschema.sql"), "dsschema.sql")
            run_sql_file(conn, os.path.join(HERE, "dsseed.sql"), "dsseed.sql")
            with conn.cursor() as cur:
                for table in ("programs", "subjects", "topics", "diagnostic_questions"):
                    cur.execute(f"select count(*) from public.{table}")
                    print(f"  {table}: {cur.fetchone()[0]} rows")
    except psycopg.Error as exc:
        # Print the DB error message but not the URL.
        print(f"DATABASE ERROR: {exc}", file=sys.stderr)
        return 1
    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

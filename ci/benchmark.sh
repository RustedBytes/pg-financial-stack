#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
pg_major=${PG_STACK_PG:-pg18}
pg_major=${pg_major#pg}
database_url=${DATABASE_URL:-postgresql://postgres:postgres@localhost:54${pg_major}/financial_stack}
exec bench/run.sh --database-url "$database_url" --workload "${WORKLOAD:-full_exchange}" --clients "${CLIENTS:-16}" --iterations "${ITERATIONS:-100}"

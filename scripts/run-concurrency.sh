#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/financial_stack}"
clients=${PG_STACK_CONCURRENCY:-16}
fx_clients=${PG_STACK_FX_CONCURRENCY:-20}
[[ $clients =~ ^[1-9][0-9]*$ && $fx_clients =~ ^[1-9][0-9]*$ ]] || {
  echo "PG_STACK_CONCURRENCY and PG_STACK_FX_CONCURRENCY must be positive integers" >&2
  exit 64
}
printf '[CONCURRENCY] ledger_clients=%s risk_clients=2 fx_clients=%s fx_attempts=100\n' \
  "$clients" "$fx_clients"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$repo_root/sql/concurrency/setup.sql"

seq 1 "$clients" | xargs -P "$clients" -I % \
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -v worker=% -f "$repo_root/sql/concurrency/ledger_worker.sql"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$repo_root/sql/concurrency/ledger_verify.sql"

seq 1 2 | xargs -P 2 -I % \
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -v worker=% -f "$repo_root/sql/concurrency/risk_worker.sql"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$repo_root/sql/concurrency/risk_verify.sql"

seq 1 100 | xargs -P "$fx_clients" -I % \
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -v worker=% -f "$repo_root/sql/concurrency/fx_worker.sql"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$repo_root/sql/concurrency/fx_verify.sql"

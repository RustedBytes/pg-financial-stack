#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/postgres}"
database=${PG_STACK_DATABASE:-financial_stack}
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v database="$database" <<'SQL'
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE datname = :'database' AND pid <> pg_backend_pid();
SELECT format('DROP DATABASE IF EXISTS %I', :'database') \gexec
SQL


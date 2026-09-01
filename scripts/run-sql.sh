#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/financial_stack}"
psql_args=("$DATABASE_URL" -X -v ON_ERROR_STOP=1)
for file in "$@"; do
  echo "[SCENARIO] $file"
  psql_args+=(-f "$file")
done
# A suite is one psql session so scenario variables and transaction-local test
# context can intentionally flow from setup through validation.
exec psql "${psql_args[@]}"

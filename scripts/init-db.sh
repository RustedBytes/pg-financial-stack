#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/financial_stack}"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "SELECT current_setting('server_version_num')::int / 10000 AS postgres_major"


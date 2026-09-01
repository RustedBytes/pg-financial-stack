#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/postgres}"
database=${PG_STACK_SCHEMA_DATABASE:-stack_schema_isolation}
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $database"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE $database"
schema_url="${DATABASE_URL%/*}/$database"
DATABASE_URL="$schema_url" "$repo_root/scripts/run-sql.sh" \
  "$repo_root/sql/compatibility/schema-isolation.sql"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "DROP DATABASE $database"

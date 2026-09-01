#!/usr/bin/env bash
set -euo pipefail

pg_major=${1#pg}
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/postgres}"

python3 - "$repo_root/stack/compatibility.toml" <<'PY' | while IFS=$'\t' read -r index order; do
import sys, tomllib
with open(sys.argv[1], "rb") as handle:
    orders = tomllib.load(handle)["installation_orders"]["supported"]
for index, order in enumerate(orders, 1):
    print(index, " ".join(order), sep="\t")
PY
  database="stack_order_${index}"
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $database"
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE $database"
  order_url="${DATABASE_URL%/*}/$database"
  SQL_ORDER="$order" DATABASE_URL="$order_url" "$repo_root/scripts/run-sql.sh" "$repo_root/sql/smoke/install-order.sql"
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "DROP DATABASE $database"
done


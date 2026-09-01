#!/usr/bin/env bash
set -euo pipefail

pg_major=${1#pg}
suite=${2:-full}
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/financial_stack}"

case "$suite" in
  smoke) files=("$repo_root/sql/smoke/install.sql") ;;
  compatibility) files=(
    "$repo_root/sql/smoke/install.sql"
    "$repo_root/sql/compatibility/adapters.sql"
    "$repo_root/sql/compatibility/types.sql"
  ) ;;
  security) files=(
    "$repo_root/sql/smoke/install.sql"
    "$repo_root/sql/compatibility/adapters.sql"
    "$repo_root/sql/security/roles.sql"
    "$repo_root/sql/security/search_path.sql"
  ) ;;
  concurrency) files=(
    "$repo_root/sql/smoke/install.sql"
    "$repo_root/sql/compatibility/adapters.sql"
    "$repo_root/sql/concurrency/setup.sql"
  ) ;;
  workflows) files=(
    "$repo_root/sql/smoke/install.sql"
    "$repo_root/sql/compatibility/adapters.sql"
    "$repo_root/sql/compatibility/types.sql"
    "$repo_root/scenarios/fiat_exchange/setup.sql"
    "$repo_root/scenarios/fiat_exchange/execute.sql"
    "$repo_root/scenarios/fiat_exchange/expected.sql"
    "$repo_root/scenarios/fiat_exchange/validate.sql"
    "$repo_root/scenarios/crypto_exchange/setup.sql"
    "$repo_root/scenarios/crypto_exchange/execute.sql"
    "$repo_root/scenarios/crypto_exchange/expected.sql"
    "$repo_root/scenarios/crypto_exchange/validate.sql"
    "$repo_root/sql/workflows/reconciliation.sql"
    "$repo_root/sql/invariants/full_stack.sql"
  ) ;;
  full) files=(
    "$repo_root/sql/smoke/install.sql"
    "$repo_root/sql/compatibility/adapters.sql"
    "$repo_root/sql/compatibility/types.sql"
    "$repo_root/scenarios/fiat_exchange/setup.sql"
    "$repo_root/scenarios/fiat_exchange/execute.sql"
    "$repo_root/scenarios/fiat_exchange/expected.sql"
    "$repo_root/scenarios/fiat_exchange/validate.sql"
    "$repo_root/scenarios/crypto_exchange/setup.sql"
    "$repo_root/scenarios/crypto_exchange/execute.sql"
    "$repo_root/scenarios/crypto_exchange/expected.sql"
    "$repo_root/scenarios/crypto_exchange/validate.sql"
    "$repo_root/sql/workflows/reconciliation.sql"
    "$repo_root/scenarios/stablecoin_identity/setup.sql"
    "$repo_root/scenarios/stablecoin_identity/execute.sql"
    "$repo_root/scenarios/stablecoin_identity/expected.sql"
    "$repo_root/scenarios/stablecoin_identity/validate.sql"
    "$repo_root/sql/security/roles.sql"
    "$repo_root/sql/security/search_path.sql"
    "$repo_root/sql/invariants/full_stack.sql"
  ) ;;
  *) echo "unknown suite: $suite" >&2; exit 64 ;;
esac

python3 "$repo_root/scripts/stack.py" verify --postgres "$pg_major"
"$repo_root/scripts/run-sql.sh" "${files[@]}"

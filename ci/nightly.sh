#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
for pg in pg14 pg15 pg16 pg17 pg18; do
  if [[ $pg == pg18 ]]; then
    PG_STACK_CONCURRENCY=${PG_STACK_CONCURRENCY:-128} scripts/docker-test.sh "$pg" full git
  else
    scripts/docker-test.sh "$pg" full git
  fi
done
scripts/compose.sh -f docker/docker-compose.yml exec -T postgres-pg18 env \
  DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres \
  /workspace/pg-financial-stack/scripts/run-install-orders.sh pg18

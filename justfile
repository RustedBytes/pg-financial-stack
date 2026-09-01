set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  @just --list

resolve mode="auto":
  scripts/resolve-extensions.sh --mode "{{mode}}"

versions:
  python3 scripts/stack.py versions

test pg="pg18":
  scripts/docker-test.sh "{{pg}}" full git

test-local pg="pg18":
  scripts/docker-test.sh "{{pg}}" full local

test-release-stack pg="pg18":
  @test -n "${PG_STACK_ARTIFACT_DIR:-}" || { echo 'PG_STACK_ARTIFACT_DIR is required' >&2; exit 64; }
  scripts/docker-test.sh "{{pg}}" full auto

test-all:
  @for pg in pg14 pg15 pg16 pg17 pg18; do scripts/docker-test.sh "$pg" full git; done

test-install-order pg="pg18":
  scripts/docker-test.sh "{{pg}}" smoke git
  service="postgres-{{pg}}"; scripts/compose.sh -f docker/docker-compose.yml exec -T "$service" env DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres /workspace/pg-financial-stack/scripts/run-install-orders.sh "{{pg}}"

test-security pg="pg18":
  scripts/docker-test.sh "{{pg}}" security git

test-concurrency pg="pg18":
  scripts/docker-test.sh "{{pg}}" smoke git
  service="postgres-{{pg}}"; scripts/compose.sh -f docker/docker-compose.yml exec -T "$service" env DATABASE_URL=postgresql://postgres:postgres@localhost:5432/financial_stack PG_STACK_CONCURRENCY="${PG_STACK_CONCURRENCY:-16}" PG_STACK_FX_CONCURRENCY="${PG_STACK_FX_CONCURRENCY:-20}" /workspace/pg-financial-stack/scripts/run-concurrency.sh

test-upgrades pg="pg18":
  scripts/run-upgrade-tests.sh "{{pg}}"

validate-stack:
  scripts/run-sql.sh sql/invariants/full_stack.sql

bench pg="pg18" workload="full_exchange" clients="16":
  pg_major="{{pg}}"; pg_major="${pg_major#pg}"; database_url="${DATABASE_URL:-postgresql://postgres:postgres@localhost:54${pg_major}/financial_stack}"; cargo run --release -p pg-financial-stack-bench -- --database-url "$database_url" --workload "{{workload}}" --clients "{{clients}}"

check-extension extension pg="pg18":
  env "PG_STACK_$(echo '{{extension}}' | tr '[:lower:]-' '[:upper:]_')_PATH=../{{extension}}" scripts/docker-test.sh "{{pg}}" full auto

smoke pg="pg18":
  scripts/docker-test.sh "{{pg}}" smoke git

nightly:
  just test-all
  just test-install-order pg18
  PG_STACK_CONCURRENCY=128 just test-concurrency pg18

release-check:
  just test-all
  just test-security pg18
  just test-concurrency pg18
  just test-install-order pg18

clean:
  scripts/cleanup.sh

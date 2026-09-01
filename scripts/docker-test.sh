#!/usr/bin/env bash
set -euo pipefail

pg_major=${1#pg}
suite=${2:-full}
mode=${3:-auto}
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
service="postgres-pg$pg_major"
compose=("$repo_root/scripts/compose.sh" -f "$repo_root/docker/docker-compose.yml")
host_uid=${PG_STACK_HOST_UID:-$(id -u)}
host_gid=${PG_STACK_HOST_GID:-$(id -g)}
[[ $host_uid =~ ^[0-9]+$ && $host_gid =~ ^[0-9]+$ ]] || {
  echo "PG_STACK_HOST_UID and PG_STACK_HOST_GID must be numeric" >&2
  exit 64
}
exec_env=()
while IFS= read -r variable; do
  exec_env+=(-e "$variable=${!variable}")
done < <(compgen -e | grep '^PG_STACK_' || true)

# Compose v1 cannot recreate a stopped container after BuildKit replaces a
# same-tag image manifest. Stack databases are disposable, so remove only this
# test service before building it again.
"${compose[@]}" --profile "pg$pg_major" rm -sf "$service" >/dev/null
"${compose[@]}" --profile "pg$pg_major" up -d --build "$service"
for attempt in $(seq 1 60); do
  if "${compose[@]}" exec -T "$service" pg_isready -U postgres >/dev/null 2>&1; then break; fi
  if [[ $attempt == 60 ]]; then
    "${compose[@]}" logs "$service" >&2
    exit 1
  fi
  sleep 1
done

container_root=/workspace/pg-financial-stack
resolver_home="/tmp/pg-stack-resolver-$host_uid"
# Resolution writes bind-mounted source checkouts and the lockfile. Run it as
# the invoking host user so later host-side `just resolve` calls remain usable.
# The chown also migrates caches produced by older root-running stack versions.
"${compose[@]}" exec -T "$service" bash -lc \
  "install -d -o '$host_uid' -g '$host_gid' '$container_root/.stack' '$container_root/.stack/extensions' '$resolver_home' && chown -R '$host_uid:$host_gid' '$container_root/.stack/extensions' && if [[ -e '$container_root/stack/versions.lock' ]]; then chown '$host_uid:$host_gid' '$container_root/stack/versions.lock'; fi"
"${compose[@]}" exec -T --user "$host_uid:$host_gid" -e HOME="$resolver_home" \
  "${exec_env[@]}" "$service" bash -lc \
  "cd '$container_root' && python3 scripts/stack.py resolve --mode '$mode'"
"${compose[@]}" exec -T "${exec_env[@]}" "$service" bash -lc \
  "cd '$container_root' && scripts/install-stack.sh '$pg_major'"
# Root is required to copy extension artifacts into PostgreSQL. Return all
# bind-mounted build caches to the invoking user once installation is done.
"${compose[@]}" exec -T "$service" chown -R "$host_uid:$host_gid" "$container_root/.stack"
"${compose[@]}" exec -T "$service" bash -lc \
  "dropdb -U postgres --if-exists financial_stack && createdb -U postgres financial_stack"
"${compose[@]}" exec -T "$service" env \
  DATABASE_URL=postgresql://postgres:postgres@localhost:5432/financial_stack \
  "$container_root/scripts/run-matrix.sh" "$pg_major" "$suite"
if [[ "$suite" == full ]]; then
  "${compose[@]}" exec -T "${exec_env[@]}" "$service" env \
    DATABASE_URL=postgresql://postgres:postgres@localhost:5432/financial_stack \
    "$container_root/scripts/run-concurrency.sh"
  "${compose[@]}" exec -T "$service" env \
    DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres \
    "$container_root/scripts/run-schema-isolation.sh"
fi

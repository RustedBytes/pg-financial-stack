#!/usr/bin/env bash
set -euo pipefail

pg_major=${1#pg}
shift || true
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export CARGO_HOME=${PG_STACK_CARGO_HOME:-$repo_root/.stack/cargo-home}
export RUSTUP_TOOLCHAIN=${PG_STACK_RUST_TOOLCHAIN:-1.96.0}
mkdir -p "$CARGO_HOME"
default_order=(pg_money pg_cryptocurrency pg_fx pg_ledger pg_reconcile pg_risk)
if (($#)); then order=("$@"); else order=("${default_order[@]}"); fi

python3 "$repo_root/scripts/stack.py" verify --postgres "$pg_major"
if [[ -z "${PG_STACK_ARTIFACT_DIR:-}" ]]; then
  cargo pgrx init "--pg$pg_major=${PG_CONFIG:-pg_config}"
fi
for extension in "${order[@]}"; do
  "$repo_root/scripts/install-extension.sh" "$extension" "$pg_major"
done
printf '%s\n' "${order[@]}" > "$repo_root/.stack/install-order-pg$pg_major.txt"

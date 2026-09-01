#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <extension-name> <pg-major> [source-path]" >&2
  exit 64
fi

name=$1
pg_major=${2#pg}
source_path=${3:-}
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export CARGO_TARGET_DIR=${PG_STACK_CARGO_TARGET_DIR:-$repo_root/.stack/targets/pg$pg_major/$name}
mkdir -p "$CARGO_TARGET_DIR"

if [[ -z "$source_path" ]]; then
  source_path=$(python3 "$repo_root/scripts/stack.py" paths | awk -F '\t' -v name="$name" '$1 == name { print $2 }')
fi
if [[ -z "$source_path" || ! -d "$source_path" ]]; then
  echo "$name: source path not found; run scripts/resolve-extensions.sh first" >&2
  exit 2
fi

if [[ -n "${PG_STACK_ARTIFACT_DIR:-}" ]]; then
  artifact="$PG_STACK_ARTIFACT_DIR/$name-pg$pg_major.tar.gz"
  [[ -f "$artifact" ]] || { echo "missing release artifact: $artifact" >&2; exit 2; }
  tar -xzf "$artifact" -C "${PG_STACK_ARTIFACT_PREFIX:-/}"
else
  attempts=${PG_STACK_BUILD_RETRIES:-3}
  for attempt in $(seq 1 "$attempts"); do
    if (cd "$source_path" && cargo pgrx install --release --pg-config "${PG_CONFIG:-pg_config}" \
      --no-default-features --features "pg$pg_major"); then
      exit 0
    fi
    if [[ $attempt == "$attempts" ]]; then
      echo "$name: build failed after $attempts attempts" >&2
      exit 1
    fi
    echo "$name: build attempt $attempt failed; retrying" >&2
    sleep 2
  done
fi

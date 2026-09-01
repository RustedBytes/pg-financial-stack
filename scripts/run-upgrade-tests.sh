#!/usr/bin/env bash
set -euo pipefail
echo "Upgrade automation is a v0.2 gate; set PG_STACK_OLD_ARTIFACT_DIR and PG_STACK_NEW_ARTIFACT_DIR." >&2
[[ -n "${PG_STACK_OLD_ARTIFACT_DIR:-}" && -n "${PG_STACK_NEW_ARTIFACT_DIR:-}" ]] || exit 64
exec "$(dirname "$0")/run-matrix.sh" "${1:-pg18}" full


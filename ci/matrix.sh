#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/../scripts/docker-test.sh" "${1:-pg18}" "${2:-full}" git


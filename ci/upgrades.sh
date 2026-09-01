#!/usr/bin/env bash
set -euo pipefail
exec "$(dirname "$0")/../scripts/run-upgrade-tests.sh" "${1:-pg18}"


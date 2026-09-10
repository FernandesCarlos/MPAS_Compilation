#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "[INFO] prepare_wps_era5.sh é um wrapper de compatibilidade; usando prepare/prepare_wps.sh" >&2
exec "$SCRIPT_DIR/prepare/prepare_wps.sh" "$@"

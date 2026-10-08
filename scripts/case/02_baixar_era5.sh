#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
python3 "$CASE_DIR/download_era5.py"

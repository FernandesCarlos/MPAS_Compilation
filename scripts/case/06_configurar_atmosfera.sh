#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
python3 "$CASE_DIR/configure_case.py" atmosphere

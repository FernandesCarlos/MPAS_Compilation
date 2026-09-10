#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
out="$(bash "$ROOT/scripts/run/full_pipeline.sh" --dry-run)"
for stage in preflight ERA5 mesh geografia build WPS partition static init atmosphere validation; do
  grep -Fqi "$stage" <<<"$out"
done
printf 'PASS full pipeline dry-run\n'

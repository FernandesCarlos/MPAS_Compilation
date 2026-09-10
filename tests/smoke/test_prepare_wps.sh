#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/era5"
: > "$tmp/era5/era5-pressure-levels.grib"
: > "$tmp/era5/era5-single-levels.grib"
output="$(DATA_ROOT="$tmp" ERA5_DIR="$tmp/era5" bash "$ROOT/scripts/prepare/prepare_wps.sh" --dry-run)"
grep -Fq 'ERA5_PRES' <<<"$output"
grep -Fq 'ERA5_SFC' <<<"$output"
grep -Fq 'link_grib.csh' <<<"$output"
grep -Fq 'ungrib.exe' <<<"$output"
grep -Fq 'ERA5:2014-09-10_00' <<<"$output"
printf 'PASS prepare_wps dry-run\n'

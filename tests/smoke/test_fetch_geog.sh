#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
out="$(bash "$ROOT/scripts/data/fetch_geog.sh" --dry-run)"
grep -Fq 'geog_high_res_mandatory.tar.gz' <<<"$out"
grep -Fq 'modis_landuse_20class_30s.tar.bz2' <<<"$out"
grep -Fq 'landuse_30s.tar.bz2' <<<"$out"
printf 'PASS fetch geog dry-run\n'

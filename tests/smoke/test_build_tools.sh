#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
out="$(bash "$ROOT/scripts/prepare/build_tools.sh" --dry-run)"
grep -Fq './configure --nowrf --build-grib2-libs' <<<"$out"
grep -Fq 'CORE=init_atmosphere' <<<"$out"
grep -Fq 'CORE=atmosphere' <<<"$out"
printf 'PASS build tools dry-run\n'

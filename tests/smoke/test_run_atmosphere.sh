#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
out="$(bash "$ROOT/scripts/run/run_atmosphere.sh" --dry-run)"
grep -Fq 'mpiexec -n 4' <<<"$out"
grep -Fq 'atmosphere_model' <<<"$out"
grep -Fq '01:00:00' <<<"$out"
grep -Fq '1200' <<<"$out"
for f in \
  history.2014-09-10_00.00.00.nc \
  history.2014-09-10_01.00.00.nc \
  diag.2014-09-10_00.00.00.nc \
  diag.2014-09-10_01.00.00.nc; do
  grep -Fq "$f" <<<"$out"
done
printf 'PASS atmosphere dry-run\n'

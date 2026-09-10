#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
out="$(bash "$ROOT/scripts/run/run_atmosphere.sh" --dry-run)"
grep -Fq 'mpiexec -n 4' <<<"$out"
grep -Fq 'atmosphere_model' <<<"$out"
grep -Fq '01:00:00' <<<"$out"
grep -Fq '1200' <<<"$out"
printf 'PASS atmosphere dry-run\n'

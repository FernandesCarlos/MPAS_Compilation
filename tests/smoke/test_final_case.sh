#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
out="$(WORK_ROOT="$tmp" bash "$ROOT/scripts/validate/final_case.sh" 2>&1 || true)"
grep -Fq 'WPS' <<<"$out"
grep -Fq 'STATIC' <<<"$out"
grep -Fq 'INIT' <<<"$out"
grep -Fq 'ATMOSPHERE' <<<"$out"
grep -Fq 'NETCDF_SANITY' <<<"$out"
grep -Fq 'FAIL' <<<"$out"
printf 'PASS final case failure report\n'

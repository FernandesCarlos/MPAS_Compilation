#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

shell_tests=(
  tests/smoke/test_case_config.sh
  tests/smoke/test_preflight.sh
  tests/smoke/test_build_tools.sh
  tests/smoke/test_prepare_wps.sh
  tests/smoke/test_fetch_geog.sh
  tests/smoke/test_prepare_mpas.sh
  tests/smoke/test_run_atmosphere.sh
  tests/smoke/test_full_pipeline.sh
  tests/smoke/test_final_case.sh
)
python_tests=(
  tests/smoke/test_era5_requests.py
  tests/smoke/test_download_era5_cli.py
  tests/smoke/test_validate_outputs.py
)

for test_file in "${shell_tests[@]}"; do
  printf '\n== %s ==\n' "$test_file"
  bash "$test_file"
done
for test_file in "${python_tests[@]}"; do
  printf '\n== %s ==\n' "$test_file"
  python3 "$test_file" -v
done
printf '\nALL SMOKE TESTS PASS\n'

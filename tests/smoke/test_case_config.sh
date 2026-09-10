#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/common.sh"
load_case_env "$ROOT/cases/first-global-240km/case.env"
[[ "$START_DATE" == "2014-09-10_00:00:00" ]]
[[ "$END_DATE" == "2014-09-10_01:00:00" ]]
[[ "$MPI_RANKS" == "4" ]]
[[ "$DT" == "1200" ]]
printf 'PASS case config\n'

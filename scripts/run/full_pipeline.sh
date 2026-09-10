#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

if [[ "${1:-}" == "--dry-run" ]]; then
  cat <<PLAN
[1/10] preflight
[2/10] ERA5 download
[3/10] mesh x1.10242
[4/10] geografia WPS_GEOG
[5/10] build WPS + MPAS
[6/10] WPS/ungrib
[7/10] partition mesh
[8/10] static + init
[9/10] atmosphere 1h
[10/10] validation PASS/FAIL
PLAN
  exit 0
fi

export FORCE="${FORCE:-0}"
run_stage() {
  local name="$1"
  shift
  log_info "===== $name ====="
  "$@"
}

download_args=()
wps_args=()
if [[ "$FORCE" == "1" ]]; then
  download_args+=(--force)
  wps_args+=(--force)
fi

run_stage preflight bash "$REPO_ROOT/scripts/validate/preflight.sh"
if [[ "${SKIP_DOWNLOAD:-0}" != "1" ]]; then
  run_stage "ERA5 download" python3 "$REPO_ROOT/scripts/data/download_era5.py" "${download_args[@]}"
  run_stage "mesh x1.10242" bash "$REPO_ROOT/scripts/data/fetch_mesh.sh"
  run_stage "geografia WPS_GEOG" bash "$REPO_ROOT/scripts/data/fetch_geog.sh"
else
  log_warn "SKIP_DOWNLOAD=1: downloads externos ignorados; entradas locais serão exigidas nas etapas seguintes."
fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  run_stage "build WPS + MPAS" bash "$REPO_ROOT/scripts/prepare/build_tools.sh"
else
  log_warn "SKIP_BUILD=1: compilação ignorada; executáveis existentes serão usados."
fi

run_stage "WPS/ungrib" bash "$REPO_ROOT/scripts/prepare/prepare_wps.sh" "${wps_args[@]}"
run_stage "partition mesh" bash "$REPO_ROOT/scripts/prepare/partition_mesh.sh"
run_stage static bash "$REPO_ROOT/scripts/prepare/generate_static.sh"
run_stage init bash "$REPO_ROOT/scripts/prepare/generate_init.sh"
run_stage atmosphere bash "$REPO_ROOT/scripts/run/run_atmosphere.sh"
run_stage validation bash "$REPO_ROOT/scripts/validate/final_case.sh"

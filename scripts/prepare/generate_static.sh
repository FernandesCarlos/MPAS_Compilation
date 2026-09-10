#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env
OUT_DIR="$WORK_ROOT/static"
OUT_FILE="$OUT_DIR/x1.10242.static.nc"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] mpiexec -n 1 $MPAS_ROOT/init_atmosphere_model"
  echo "[DRY-RUN] output $OUT_FILE"
  exit 0
fi

require_file "$MESH_FILE"
require_dir "$WPS_GEOG"
[[ -x "$MPAS_ROOT/init_atmosphere_model" ]] || die "init_atmosphere_model ausente. Execute scripts/prepare/build_tools.sh"
require_file "$CASE_ROOT/static/namelist.init_atmosphere"
require_file "$CASE_ROOT/static/streams.init_atmosphere"
if [[ -s "$OUT_FILE" && "${FORCE:-0}" != "1" ]]; then
  log_info "static já existe: $OUT_FILE"
  exit 0
fi
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp "$CASE_ROOT/static/namelist.init_atmosphere" "$OUT_DIR/"
cp "$CASE_ROOT/static/streams.init_atmosphere" "$OUT_DIR/"
ln -s "$MESH_FILE" "$OUT_DIR/x1.10242.grid.nc"
ln -s "$WPS_GEOG" "$OUT_DIR/geog"
(
  cd "$OUT_DIR"
  run_logged "$WORK_ROOT/logs/static.log" mpiexec -n 1 "$MPAS_ROOT/init_atmosphere_model"
)
require_file "$OUT_FILE"
log_info "static gerado: $OUT_FILE"

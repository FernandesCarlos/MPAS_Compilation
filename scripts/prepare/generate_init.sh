#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env
STATIC_FILE="$WORK_ROOT/static/x1.10242.static.nc"
WPS_FILE="$WORK_ROOT/wps/ERA5:2014-09-10_00"
GRAPH_FILE="$(dirname "$MESH_FILE")/x1.10242.graph.info"
PART_FILE="${GRAPH_FILE}.part.${MPI_RANKS}"
OUT_DIR="$WORK_ROOT/init"
OUT_FILE="$OUT_DIR/x1.10242.init.nc"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] mpiexec -n $MPI_RANKS $MPAS_ROOT/init_atmosphere_model"
  echo "[DRY-RUN] input $STATIC_FILE + $WPS_FILE + $PART_FILE"
  echo "[DRY-RUN] output $OUT_FILE"
  exit 0
fi
require_file "$STATIC_FILE"
require_file "$WPS_FILE"
require_file "$PART_FILE"
[[ -x "$MPAS_ROOT/init_atmosphere_model" ]] || die "init_atmosphere_model ausente. Execute scripts/prepare/build_tools.sh"
if [[ -s "$OUT_FILE" && "${FORCE:-0}" != "1" ]]; then
  log_info "init já existe: $OUT_FILE"
  exit 0
fi
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp "$CASE_ROOT/init/namelist.init_atmosphere" "$OUT_DIR/"
cp "$CASE_ROOT/init/streams.init_atmosphere" "$OUT_DIR/"
ln -s "$STATIC_FILE" "$OUT_DIR/x1.10242.static.nc"
ln -s "$WPS_FILE" "$OUT_DIR/ERA5:2014-09-10_00"
ln -s "$PART_FILE" "$OUT_DIR/x1.10242.graph.info.part.${MPI_RANKS}"
[[ -d "$WPS_GEOG" ]] && ln -s "$WPS_GEOG" "$OUT_DIR/geog"
(
  cd "$OUT_DIR"
  run_logged "$WORK_ROOT/logs/init.log" mpiexec -n "$MPI_RANKS" "$MPAS_ROOT/init_atmosphere_model"
)
require_file "$OUT_FILE"
log_info "init gerado: $OUT_FILE"

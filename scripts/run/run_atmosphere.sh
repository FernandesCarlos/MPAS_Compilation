#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

INIT_FILE="$WORK_ROOT/init/x1.10242.init.nc"
GRAPH_FILE="$(dirname "$MESH_FILE")/x1.10242.graph.info"
PART_FILE="${GRAPH_FILE}.part.${MPI_RANKS}"
OUT_DIR="$WORK_ROOT/atmosphere"
LOOKUP_SOURCE="$MPAS_ROOT/src/core_atmosphere/physics/physics_wrf/files"
LOOKUP_TABLES=(
  CAM_ABS_DATA.DBL CAM_AEROPT_DATA.DBL CCN_ACTIVATE_DATA GENPARM.TBL
  LANDUSE.TBL OZONE_DAT.TBL OZONE_LAT.TBL OZONE_PLEV.TBL
  RRTMG_LW_DATA RRTMG_LW_DATA.DBL RRTMG_SW_DATA RRTMG_SW_DATA.DBL
  SOILPARM.TBL VEGPARM.TBL
)
CONFIG_FILES=(
  namelist.atmosphere streams.atmosphere stream_list.atmosphere.output
  stream_list.atmosphere.diagnostics stream_list.atmosphere.diag_ugwp
  stream_list.atmosphere.surface
)

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] baseline: start=$START_DATE duration=$RUN_DURATION dt=${DT}s ranks=$MPI_RANKS"
  echo "[DRY-RUN] mpiexec -n $MPI_RANKS $MPAS_ROOT/atmosphere_model"
  echo "[DRY-RUN] output $OUT_DIR/history.*.nc + $OUT_DIR/diag.*.nc"
  exit 0
fi

require_file "$INIT_FILE"
require_file "$PART_FILE"
[[ -x "$MPAS_ROOT/atmosphere_model" ]] || die "atmosphere_model ausente. Execute scripts/prepare/build_tools.sh"
for f in "${CONFIG_FILES[@]}"; do require_file "$CASE_ROOT/atmosphere/$f"; done
for table in "${LOOKUP_TABLES[@]}"; do require_file "$LOOKUP_SOURCE/$table"; done

if compgen -G "$OUT_DIR/history.*.nc" >/dev/null && [[ "${FORCE:-0}" != "1" ]]; then
  log_info "Execução atmosphere já possui history em $OUT_DIR; pulando."
  exit 0
fi
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
ln -s "$INIT_FILE" "$OUT_DIR/x1.10242.init.nc"
ln -s "$PART_FILE" "$OUT_DIR/x1.10242.graph.info.part.${MPI_RANKS}"
for f in "${CONFIG_FILES[@]}"; do cp "$CASE_ROOT/atmosphere/$f" "$OUT_DIR/$f"; done
for table in "${LOOKUP_TABLES[@]}"; do ln -s "$LOOKUP_SOURCE/$table" "$OUT_DIR/$table"; done

(
  cd "$OUT_DIR"
  run_logged "$WORK_ROOT/logs/atmosphere.log" mpiexec -n "$MPI_RANKS" "$MPAS_ROOT/atmosphere_model"
)

mapfile -t histories < <(find "$OUT_DIR" -maxdepth 1 -type f -name 'history.*.nc' -print | sort)
mapfile -t diagnostics < <(find "$OUT_DIR" -maxdepth 1 -type f -name 'diag.*.nc' -print | sort)
[[ ${#histories[@]} -gt 0 ]] || die "atmosphere_model não gerou arquivos history"
[[ ${#diagnostics[@]} -gt 0 ]] || die "atmosphere_model não gerou arquivos diagnostics"

python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" \
  "${histories[@]}" --require-var t2m --require-time
python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" \
  "${diagnostics[@]}" --require-time

log_info "Execução atmosphere concluída: $OUT_DIR"

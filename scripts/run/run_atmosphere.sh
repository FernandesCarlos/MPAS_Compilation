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
EXPECTED_HISTORY=(
  history.2014-09-10_00.00.00.nc
  history.2014-09-10_01.00.00.nc
)
EXPECTED_DIAGNOSTICS=(
  diag.2014-09-10_00.00.00.nc
  diag.2014-09-10_01.00.00.nc
)

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] baseline: start=$START_DATE duration=$RUN_DURATION dt=${DT}s ranks=$MPI_RANKS"
  echo "[DRY-RUN] mpiexec -n $MPI_RANKS $MPAS_ROOT/atmosphere_model"
  for f in "${EXPECTED_HISTORY[@]}"; do
    echo "[DRY-RUN] expected history: $OUT_DIR/$f"
  done
  for f in "${EXPECTED_DIAGNOSTICS[@]}"; do
    echo "[DRY-RUN] expected diagnostics: $OUT_DIR/$f"
  done
  exit 0
fi

require_file "$INIT_FILE"
require_file "$PART_FILE"
[[ -x "$MPAS_ROOT/atmosphere_model" ]] || die "atmosphere_model ausente. Execute scripts/prepare/build_tools.sh"
for f in "${CONFIG_FILES[@]}"; do require_file "$CASE_ROOT/atmosphere/$f"; done
for table in "${LOOKUP_TABLES[@]}"; do require_file "$LOOKUP_SOURCE/$table"; done

all_outputs_present=1
for f in "${EXPECTED_HISTORY[@]}" "${EXPECTED_DIAGNOSTICS[@]}"; do
  [[ -s "$OUT_DIR/$f" ]] || all_outputs_present=0
done
if [[ "$all_outputs_present" == "1" && "${FORCE:-0}" != "1" ]]; then
  log_info "Execução atmosphere da baseline já está completa em $OUT_DIR; pulando."
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

for f in "${EXPECTED_HISTORY[@]}"; do
  [[ -s "$OUT_DIR/$f" ]] || die "atmosphere_model não gerou o history esperado: $f"
done
for f in "${EXPECTED_DIAGNOSTICS[@]}"; do
  [[ -s "$OUT_DIR/$f" ]] || die "atmosphere_model não gerou o diagnostics esperado: $f"
done

python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" \
  "${EXPECTED_HISTORY[@]/#/$OUT_DIR/}" --require-var t2m --require-time
python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" \
  "${EXPECTED_DIAGNOSTICS[@]/#/$OUT_DIR/}" --require-time

log_info "Execução atmosphere concluída: $OUT_DIR"

#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

ERA5_DIR="${ERA5_DIR:-$DATA_ROOT/era5}"
WPS_WORK="${WPS_WORK:-$WORK_ROOT/wps}"
TIMESTAMP="2014-09-10_00"
DRY_RUN=0
FORCE="${FORCE:-0}"
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    *) die "Argumento desconhecido: $arg" ;;
  esac
done

pressure_grib="$ERA5_DIR/era5-pressure-levels.grib"
single_grib="$ERA5_DIR/era5-single-levels.grib"
combined="$WPS_WORK/ERA5:${TIMESTAMP}"

if (( DRY_RUN )); then
  cat <<PLAN
[DRY-RUN] $WPS_ROOT/link_grib.csh $pressure_grib
[DRY-RUN] Vtable -> $WPS_ROOT/ungrib/Variable_Tables/Vtable.ECMWF
[DRY-RUN] $WPS_ROOT/ungrib.exe -> ERA5_PRES:${TIMESTAMP}
[DRY-RUN] $WPS_ROOT/link_grib.csh $single_grib
[DRY-RUN] Vtable -> $WPS_ROOT/ungrib/Variable_Tables/Vtable.ECMWF
[DRY-RUN] $WPS_ROOT/ungrib.exe -> ERA5_SFC:${TIMESTAMP}
[DRY-RUN] cat ERA5_PRES:${TIMESTAMP} ERA5_SFC:${TIMESTAMP} > ERA5:${TIMESTAMP}
PLAN
  exit 0
fi

require_file "$pressure_grib"
require_file "$single_grib"
require_file "$WPS_ROOT/link_grib.csh"
require_file "$WPS_ROOT/ungrib/Variable_Tables/Vtable.ECMWF"
[[ -x "$WPS_ROOT/ungrib.exe" ]] || die "ungrib.exe não encontrado. Execute scripts/prepare/build_tools.sh"
mkdir -p "$WPS_WORK"

run_one() {
  local kind="$1" prefix="$2" grib="$3" config="$4"
  local stage="$WPS_WORK/$kind"
  local output="$WPS_WORK/${prefix}:${TIMESTAMP}"
  if [[ -s "$output" && "$FORCE" != "1" ]]; then
    log_info "$output já existe; pulando $kind."
    return
  fi
  rm -rf "$stage"
  mkdir -p "$stage"
  cp "$config" "$stage/namelist.wps"
  ln -sf "$WPS_ROOT/ungrib/Variable_Tables/Vtable.ECMWF" "$stage/Vtable"
  (
    cd "$stage"
    rm -f GRIBFILE.??? "${prefix}:"* ungrib.log
    "$WPS_ROOT/link_grib.csh" "$grib"
    run_logged "$WORK_ROOT/logs/ungrib-${kind}.log" "$WPS_ROOT/ungrib.exe"
    local produced="${prefix}:${TIMESTAMP}"
    require_file "$stage/$produced"
    cp "$stage/$produced" "$output"
  )
}

run_one pressure ERA5_PRES "$pressure_grib" "$CASE_ROOT/wps/pressure/namelist.wps"
run_one single ERA5_SFC "$single_grib" "$CASE_ROOT/wps/single/namelist.wps"

if [[ -s "$combined" && "$FORCE" != "1" ]]; then
  log_info "$combined já existe; mantendo arquivo combinado."
else
  cat "$WPS_WORK/ERA5_PRES:${TIMESTAMP}" "$WPS_WORK/ERA5_SFC:${TIMESTAMP}" > "$combined"
fi
require_file "$combined"
log_info "WPS ERA5 concluído: $combined"

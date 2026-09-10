#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
export NETCDF="${NETCDF:-/dependencias/netcdf}"
export PNETCDF="${PNETCDF:-/dependencias/pnetcdf}"
export PIO="${PIO:-/dependencias/pio}"
export PATH="${NETCDF}/bin:${PNETCDF}/bin:${PIO}/bin:/dependencias/metis/bin:${PATH}"
export LD_LIBRARY_PATH="/dependencias/zlib/lib:/dependencias/hdf5/lib:${NETCDF}/lib:${PNETCDF}/lib:${PIO}/lib:/dependencias/metis/lib:${LD_LIBRARY_PATH:-}"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] cd $WPS_ROOT && ./configure --nowrf --build-grib2-libs && ./compile ungrib"
  echo "[DRY-RUN] cd $MPAS_ROOT && make -j${BUILD_JOBS} gnu CORE=init_atmosphere USE_PIO2=true"
  echo "[DRY-RUN] cd $MPAS_ROOT && make -j${BUILD_JOBS} gnu CORE=atmosphere USE_PIO2=true"
  exit 0
fi

check_linkage() {
  local exe="$1"
  require_file "$exe"
  if command -v ldd >/dev/null 2>&1 && ldd "$exe" | grep -q 'not found'; then
    die "Biblioteca não resolvida em $exe"
  fi
}

build_wps() {
  if [[ -x "$WPS_ROOT/ungrib.exe" ]]; then
    log_info "ungrib.exe já existe; pulando compilação do WPS."
    return
  fi
  require_file "$WPS_ROOT/configure"
  cd "$WPS_ROOT"
  if [[ ! -f configure.wps ]]; then
    local option
    option="${WPS_CONFIG_OPTION:-}"
    if [[ -z "$option" ]]; then
      option="$(awk '
        /^#ARCH/ && /Linux/ && /x86_64/ {
          n++
          if (/gfortran/ && /serial/ && chosen == "") chosen=n
        }
        END { if (chosen != "") print chosen }
      ' arch/configure.defaults)"
    fi
    [[ -n "$option" ]] || die "Não foi possível detectar a opção GNU serial do WPS. Defina WPS_CONFIG_OPTION."
    log_info "Configurando WPS com opção $option"
    printf '%s\n' "$option" | ./configure --nowrf --build-grib2-libs
  fi
  run_logged "$WORK_ROOT/logs/build-wps.log" ./compile ungrib
  check_linkage "$WPS_ROOT/ungrib.exe"
}

build_mpas_core() {
  local core="$1" exe="$2"
  if [[ -x "$MPAS_ROOT/$exe" ]]; then
    log_info "$exe já existe; pulando CORE=$core."
    return
  fi
  require_file "$MPAS_ROOT/Makefile"
  cd "$MPAS_ROOT"
  run_logged "$WORK_ROOT/logs/build-mpas-${core}.log" \
    make -j"$BUILD_JOBS" gnu "CORE=$core" USE_PIO2=true
  check_linkage "$MPAS_ROOT/$exe"
}

build_wps
build_mpas_core init_atmosphere init_atmosphere_model
build_mpas_core atmosphere atmosphere_model
log_info "Ferramentas da baseline prontas."

#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

CONFIG_ONLY=0
if [[ "${1:-}" == "--config-only" ]]; then
  CONFIG_ONLY=1
fi

[[ "$START_DATE" == "2014-09-10_00:00:00" ]] || die "START_DATE fora da baseline: $START_DATE"
[[ "$MPI_RANKS" =~ ^[1-9][0-9]*$ ]] || die "MPI_RANKS inválido: $MPI_RANKS"
[[ "$DT" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "DT inválido: $DT"

if (( CONFIG_ONLY )); then
  log_info "Configuração da baseline válida: ${START_DATE}, ${MPI_RANKS} ranks, dt=${DT}s"
  exit 0
fi

for cmd in bash python3 make gcc gfortran mpicc mpif90 mpiexec; do
  require_command "$cmd"
done
require_dir "$WPS_ROOT"
require_dir "$MPAS_ROOT"
[[ -f "$WPS_ROOT/configure" ]] || die "WPS incompleto: configure não encontrado em $WPS_ROOT"
[[ -f "$MPAS_ROOT/Makefile" ]] || die "MPAS incompleto: Makefile não encontrado em $MPAS_ROOT"

for cmd in nc-config nf-config gpmetis; do
  require_command "$cmd"
done

log_info "Preflight concluído. Fontes e toolchain estão disponíveis."
if [[ ! -x "$WPS_ROOT/ungrib.exe" ]]; then log_warn "ungrib.exe ausente; build_tools.sh irá compilá-lo."; fi
if [[ ! -x "$MPAS_ROOT/init_atmosphere_model" ]]; then log_warn "init_atmosphere_model ausente; build_tools.sh irá compilá-lo."; fi
if [[ ! -x "$MPAS_ROOT/atmosphere_model" ]]; then log_warn "atmosphere_model ausente; build_tools.sh irá compilá-lo."; fi

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_LIB_DIR}/../.." && pwd)"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
die() { log_error "$*"; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatório não encontrado: $1"
}

require_file() {
  [[ -s "$1" ]] || die "Arquivo obrigatório ausente ou vazio: $1"
}

require_dir() {
  [[ -d "$1" ]] || die "Diretório obrigatório não encontrado: $1"
}

load_case_env() {
  local env_file="${1:-${REPO_ROOT}/cases/first-global-240km/case.env}"
  [[ -r "$env_file" ]] || die "Configuração do caso não encontrada: $env_file"
  # shellcheck disable=SC1090
  source "$env_file"
  export CASE_ROOT DATA_ROOT WORK_ROOT WPS_ROOT MPAS_ROOT MESH_FILE WPS_GEOG
  export MPI_RANKS START_DATE END_DATE RUN_DURATION DT
  mkdir -p "$DATA_ROOT" "$WORK_ROOT" "$WORK_ROOT/logs"
}

run_logged() {
  local log_file="$1"
  shift
  mkdir -p "$(dirname "$log_file")"
  log_info "Executando: $*"
  "$@" 2>&1 | tee "$log_file"
  local rc=${PIPESTATUS[0]}
  return "$rc"
}

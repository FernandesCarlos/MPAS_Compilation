#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env
GRAPH_FILE="${GRAPH_FILE:-$(dirname "$MESH_FILE")/x1.10242.graph.info}"
PART_FILE="${GRAPH_FILE}.part.${MPI_RANKS}"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] gpmetis -minconn -contig -niter=200 $GRAPH_FILE $MPI_RANKS -> $PART_FILE"
  exit 0
fi
require_command gpmetis
require_file "$GRAPH_FILE"
if [[ -s "$PART_FILE" && "${FORCE:-0}" != "1" ]]; then
  log_info "Particionamento já existe: $PART_FILE"
  exit 0
fi
(
  cd "$(dirname "$GRAPH_FILE")"
  gpmetis -minconn -contig -niter=200 "$(basename "$GRAPH_FILE")" "$MPI_RANKS" \
    2>&1 | tee "$WORK_ROOT/logs/partition-mesh.log"
)
require_file "$PART_FILE"
log_info "Partição gerada: $PART_FILE"

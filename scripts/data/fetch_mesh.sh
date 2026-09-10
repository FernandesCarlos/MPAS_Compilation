#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

SOURCE_URL="${MESH_URL:-https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.10242.tar.gz}"
SOURCE_SHA256="${MESH_SHA256:-4dde31932bc45aaf467e2717d17ec8e5e54d73c3ebbeea027087bfdb8b98ab56}"
DEST_DIR="$(dirname "$MESH_FILE")"
GRAPH_FILE="$DEST_DIR/x1.10242.graph.info"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] download $SOURCE_URL"
  echo "[DRY-RUN] verify sha256 $SOURCE_SHA256"
  echo "[DRY-RUN] install $MESH_FILE and $GRAPH_FILE"
  exit 0
fi

if [[ -s "$MESH_FILE" && -s "$GRAPH_FILE" ]]; then
  log_info "Malha x1.10242 já está disponível em $DEST_DIR"
  exit 0
fi

for cmd in curl sha256sum tar awk mktemp; do require_command "$cmd"; done
mkdir -p "$DEST_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
archive="$tmp/x1.10242.tar.gz"
curl -fL --retry 3 -o "$archive" "$SOURCE_URL"
echo "$SOURCE_SHA256  $archive" | sha256sum -c -
tar -xzf "$archive" -C "$tmp" -- x1.10242.grid.nc x1.10242.graph.info
require_file "$tmp/x1.10242.grid.nc"
require_file "$tmp/x1.10242.graph.info"
read -r vertices edges < <(awk '!/^%/ && NF {print $1, $2; exit}' "$tmp/x1.10242.graph.info")
[[ "$vertices" == "10242" && "${edges:-0}" -gt 0 ]] || die "Cabeçalho inesperado no graph.info: $vertices $edges"
install -m 0644 "$tmp/x1.10242.grid.nc" "$MESH_FILE"
install -m 0644 "$tmp/x1.10242.graph.info" "$GRAPH_FILE"
log_info "Malha instalada em $DEST_DIR"

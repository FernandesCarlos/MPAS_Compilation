#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
# Usa a malha e o arquivo estático preparados pelo NCAR.
python3 "$CASE_DIR/download_mesh.py"
if [[ "$NP" -gt 1 ]]; then
    bash "$CASE_DIR/../mpas.sh" partition "$RUN_DIR/$MESH.graph.info"
fi

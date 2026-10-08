#!/usr/bin/env bash
set -euo pipefail
CASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
set -a
source "${CASE_CONFIG:-$CASE_DIR/caso.env}"
set +a
fail() { echo "ERRO: $*" >&2; exit 1; }
RUN_DIR=$(realpath -m -- "$RUN_DIR")
ERA5_DIR=$(realpath -m -- "$ERA5_DIR")
WPS_DIR=$(realpath -m -- "$WPS_DIR")
export RUN_DIR ERA5_DIR WPS_DIR
[[ "$NP" =~ ^[1-9][0-9]*$ ]] || fail 'NP deve ser inteiro positivo.'
[[ "$MESH" == x1.10242 ]] || fail 'Este caso usa a malha global x1.10242; adapte URLs e parâmetros para outra malha.'
python3 - "$START_TIME" <<'PY'
from datetime import datetime
import sys
try:
    value = datetime.strptime(sys.argv[1], '%Y-%m-%d_%H:%M:%S')
    if value.minute or value.second:
        raise ValueError('ERA5 deste caso usa horários inteiros')
except ValueError as error:
    sys.exit(f'ERRO: START_TIME inválido: {error}')
PY

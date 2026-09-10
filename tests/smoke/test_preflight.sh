#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

bash "$ROOT/scripts/validate/preflight.sh" --config-only >/tmp/preflight-ok.txt

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if MPAS_ROOT="$tmp" WPS_ROOT="$tmp" bash "$ROOT/scripts/validate/preflight.sh" >/tmp/preflight-fail.txt 2>&1; then
  echo "preflight deveria falhar com runtime ausente" >&2
  exit 1
fi
grep -Eq 'MPAS|WPS|Comando obrigatório|executável' /tmp/preflight-fail.txt
printf 'PASS preflight\n'

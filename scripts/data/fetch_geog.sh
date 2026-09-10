#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

HIGH_URL="https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz"
HIGH_SHA="89b026b9db0a03c0c995e53b4a1d99663af1f6bda21b3b34c3c2c07386da5493"
LANDUSE_URL="https://www2.mmm.ucar.edu/wrf/src/wps_files/modis_landuse_20class_30s.tar.bz2"
LANDUSE_SHA="b21ca154d1038ec271abaa1be2fd38a0cd055b8a4ddfaab520719478ac48d326"
GWD_URL="https://www2.mmm.ucar.edu/wrf/src/wps_files/landuse_30s.tar.bz2"
GWD_SHA="143cd195ae91f64011a43eae52ca00228709672c6a2ba614cb437eeb4cd41160"
CACHE_DIR="${GEOG_CACHE_DIR:-$DATA_ROOT/.archives}"
REQUIRED=(albedo_modis greenfrac_fpar_modis maxsnowalb_modis landuse_30s modis_landuse_20class_30s soiltemp_1deg soiltype_top_30s topo_gmted2010_30s)

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] $HIGH_URL"
  echo "[DRY-RUN] $LANDUSE_URL"
  echo "[DRY-RUN] $GWD_URL"
  echo "[DRY-RUN] destination $WPS_GEOG"
  exit 0
fi

complete=1
for d in "${REQUIRED[@]}"; do [[ -s "$WPS_GEOG/$d/index" ]] || complete=0; done
if (( complete )) && [[ "${FORCE:-0}" != "1" ]]; then
  log_info "Dados geográficos já disponíveis: $WPS_GEOG"
  exit 0
fi
if [[ -e "$WPS_GEOG" && "${FORCE:-0}" != "1" ]]; then
  die "WPS_GEOG existe mas está incompleto: $WPS_GEOG. Use FORCE=1 para reconstruir."
fi
for cmd in curl sha256sum tar mktemp; do require_command "$cmd"; done
mkdir -p "$CACHE_DIR" "$(dirname "$WPS_GEOG")"

fetch() {
  local url="$1" sha="$2" name="$3"
  local path="$CACHE_DIR/$name"
  if [[ ! -s "$path" ]]; then
    log_info "Baixando $name" >&2
    curl -fL --retry 5 --retry-all-errors --continue-at - -o "$path.part" "$url"
    mv "$path.part" "$path"
  fi
  echo "$sha  $path" | sha256sum -c - >/dev/null
  printf '%s\n' "$path"
}

high="$(fetch "$HIGH_URL" "$HIGH_SHA" geog_high_res_mandatory.tar.gz)"
land="$(fetch "$LANDUSE_URL" "$LANDUSE_SHA" modis_landuse_20class_30s.tar.bz2)"
gwd="$(fetch "$GWD_URL" "$GWD_SHA" landuse_30s.tar.bz2)"
stage="$(mktemp -d "$(dirname "$WPS_GEOG")/.geog-stage.XXXXXX")"
trap 'rm -rf "$stage"' EXIT

tar -xzf "$high" -C "$stage" --strip-components=1 -- \
  WPS_GEOG/albedo_modis \
  WPS_GEOG/greenfrac_fpar_modis \
  WPS_GEOG/maxsnowalb_modis \
  WPS_GEOG/soiltemp_1deg \
  WPS_GEOG/soiltype_top_30s \
  WPS_GEOG/topo_gmted2010_30s
tar -xjf "$land" -C "$stage" -- modis_landuse_20class_30s
tar -xjf "$gwd" -C "$stage" -- landuse_30s
for d in "${REQUIRED[@]}"; do require_file "$stage/$d/index"; done
rm -rf "$WPS_GEOG"
mv "$stage" "$WPS_GEOG"
trap - EXIT
log_info "Dados geográficos instalados em $WPS_GEOG"

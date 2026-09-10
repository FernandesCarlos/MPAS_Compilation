#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
load_case_env

WPS_FILE="$WORK_ROOT/wps/ERA5:2014-09-10_00"
STATIC_FILE="$WORK_ROOT/static/x1.10242.static.nc"
INIT_FILE="$WORK_ROOT/init/x1.10242.init.nc"
ATM_DIR="$WORK_ROOT/atmosphere"

status_wps=FAIL
status_static=FAIL
status_init=FAIL
status_atmosphere=FAIL
status_netcdf=FAIL

[[ -s "$WPS_FILE" ]] && status_wps=PASS
if [[ -s "$STATIC_FILE" ]]; then
  if python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" "$STATIC_FILE" >/dev/null 2>&1; then
    status_static=PASS
  fi
fi
if [[ -s "$INIT_FILE" ]]; then
  if python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" "$INIT_FILE" --require-time >/dev/null 2>&1; then
    status_init=PASS
  fi
fi

mapfile -t histories < <(find "$ATM_DIR" -maxdepth 1 -type f -name 'history.*.nc' -print 2>/dev/null | sort)
mapfile -t diagnostics < <(find "$ATM_DIR" -maxdepth 1 -type f -name 'diag.*.nc' -print 2>/dev/null | sort)
if [[ ${#histories[@]} -gt 0 && ${#diagnostics[@]} -gt 0 ]]; then
  status_atmosphere=PASS
  if python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" \
      "${histories[@]}" --require-var t2m --require-time >/dev/null 2>&1 \
    && python3 "$REPO_ROOT/scripts/validate/validate_outputs.py" \
      "${diagnostics[@]}" --require-time >/dev/null 2>&1; then
    status_netcdf=PASS
  fi
fi

printf '%-18s %s\n' WPS "$status_wps"
printf '%-18s %s\n' STATIC "$status_static"
printf '%-18s %s\n' INIT "$status_init"
printf '%-18s %s\n' ATMOSPHERE "$status_atmosphere"
printf '%-18s %s\n' NETCDF_SANITY "$status_netcdf"

for value in "$status_wps" "$status_static" "$status_init" "$status_atmosphere" "$status_netcdf"; do
  [[ "$value" == PASS ]] || exit 1
done

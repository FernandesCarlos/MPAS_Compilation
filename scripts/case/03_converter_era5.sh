#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ -x "$WPS_DIR/ungrib.exe" ]] || fail "Execute 02a_preparar_wps.sh para compilar ungrib.exe em $WPS_DIR."
WPS_VTABLE=${WPS_VTABLE:-$RUN_DIR/Vtable.ERA5}
[[ -s "$WPS_VTABLE" ]] || fail 'Execute 02a_preparar_wps.sh para preparar a Vtable, ou defina WPS_VTABLE.'
hour=${START_TIME:0:13}
pressure="$ERA5_DIR/$hour/era5_pressure_levels.grib"
surface="$ERA5_DIR/$hour/era5_single_levels.grib"
[[ -s "$pressure" && -s "$surface" ]] || fail 'Execute 02_baixar_era5.sh para a data configurada.'
python3 "$CASE_DIR/wps_tools.py" check-table "$WPS_VTABLE" "$pressure" "$surface"
pressure=$(realpath -- "$pressure")
surface=$(realpath -- "$surface")
vtable=$(realpath -- "$WPS_VTABLE")
mkdir -p -- "$RUN_DIR/wps_$hour"
cd -- "$RUN_DIR/wps_$hour"
[[ ! -f namelist.wps ]] || cp -- namelist.wps "namelist.wps.bak.$(date +%s%N)"
cat > namelist.wps <<EOF
&share
 start_date = '$START_TIME',
 end_date = '$START_TIME',
 interval_seconds = 3600,
/
&ungrib
 out_format = 'WPS',
 prefix = 'ERA5',
/
EOF
ln -sfn -- "$vtable" Vtable
# Diretório próprio desta conversão; vincula os dois GRIB em uma execução.
ln -sfn -- "$pressure" GRIBFILE.AAA
ln -sfn -- "$surface" GRIBFILE.AAB
# Retira a saída anterior para exigir um intermediário novo nesta execução.
[[ ! -e "ERA5:$hour" ]] || mv -- "ERA5:$hour" "ERA5:$hour.bak.$(date +%s%N)"
"$WPS_DIR/ungrib.exe"
[[ -s "ERA5:$hour" ]] || fail "ungrib não gerou ERA5:$hour"
if [[ -x "$WPS_DIR/util/rd_intermediate.exe" ]]; then
    "$WPS_DIR/util/rd_intermediate.exe" "ERA5:$hour"
fi
cp -- "ERA5:$hour" "$RUN_DIR/"
echo "Intermediário copiado para $RUN_DIR/ERA5:$hour. Confira os campos antes de inicializar."

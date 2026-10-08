#!/usr/bin/env bash
# Execute dentro do contêiner, após baixar ERA5 e antes de converter.
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ -d "$WPS_DIR" ]] || fail "Código do WPS ausente em $WPS_DIR."
mkdir -p -- "$RUN_DIR/wps_build"
ready=true
for exe in ungrib.exe util/g1print.exe util/g2print.exe util/rd_intermediate.exe; do
    [[ -s "$WPS_DIR/$exe" && -x "$WPS_DIR/$exe" ]] || ready=false
done
if [[ "$ready" != true || "${FORCE_WPS_REBUILD:-0}" == 1 ]]; then
    for tool in gcc gfortran csh perl make cmake; do
        command -v "$tool" >/dev/null || fail "Comando necessário para compilar WPS: $tool"
    done
    export NETCDF=${NETCDF:-/dependencias/netcdf}
    [[ -f "$NETCDF/include/netcdf.inc" ]] || fail "NetCDF-Fortran não encontrado em $NETCDF."
    for script in configure compile clean; do
        [[ -x "$WPS_DIR/$script" ]] || fail "Script do WPS ausente: $WPS_DIR/$script"
    done
    # Descobre a opção gfortran serial no menu desta arquitetura.
    selection=$(python3 "$CASE_DIR/wps_tools.py" option "$WPS_DIR/arch/configure.defaults")
    cd -- "$WPS_DIR"
    [[ ! -f configure.wps ]] || cp -- configure.wps "$RUN_DIR/wps_build/configure.wps.bak.$(date +%s%N)"
    # A limpeza remove produtos antigos para que não mascarem uma compilação falha.
    ./clean -a
    printf '%s\n' "$selection" | ./configure --nowrf --build-grib2-libs 2>&1 | tee "$RUN_DIR/wps_build/configure.log"
    [[ -s configure.wps ]] || fail 'WPS não gerou configure.wps.'
    for target in ungrib g1print g2print rd_intermediate; do
        ./compile "$target" 2>&1 | tee "$RUN_DIR/wps_build/compile_$target.log"
        if [[ "$target" == ungrib ]]; then output=ungrib.exe; else output="util/$target.exe"; fi
        # WPS usa make -i: o retorno zero sozinho não comprova a compilação.
        [[ -s "$output" && -x "$output" ]] || fail "Compilação não gerou $output; consulte $RUN_DIR/wps_build/compile_$target.log"
    done
else
    echo "Reutilizando os executáveis existentes em $WPS_DIR (FORCE_WPS_REBUILD=1 recompila)."
fi
table=${WPS_VTABLE:-$WPS_DIR/ungrib/Variable_Tables/Vtable.ERA-interim.pl}
[[ -s "$table" ]] || fail "Vtable ausente ou vazia: $table"
destination="$RUN_DIR/Vtable.ERA5"
if [[ "$(realpath -- "$table")" != "$(realpath -m -- "$destination")" ]]; then
    [[ ! -e "$destination" ]] || cp -- "$destination" "$destination.bak.$(date +%s%N)"
    cp -- "$table" "$destination"
fi
hour=${START_TIME:0:13}
pressure="$ERA5_DIR/$hour/era5_pressure_levels.grib"
surface="$ERA5_DIR/$hour/era5_single_levels.grib"
if [[ -s "$pressure" && -s "$surface" ]]; then
    python3 "$CASE_DIR/wps_tools.py" check-table "$destination" "$pressure" "$surface"
else
    echo 'GRIB ainda indisponível: a compatibilidade da edição será verificada na conversão.'
fi
echo "WPS preparado. Vtable disponível em $destination."
echo 'A tabela padrão é GRIB1; para GRIB2 informe uma Vtable com os códigos correspondentes em WPS_VTABLE.'

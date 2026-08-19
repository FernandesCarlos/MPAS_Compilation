#!/usr/bin/env bash
set -euo pipefail

export WPS_DIR="${WPS_DIR:-/build/WPS}"
export ERA5_DIR="${ERA5_DIR:-/dados/era5}"

if [ ! -d "$WPS_DIR" ]; then
  echo "[ERROR] Diretório do WPS não encontrado: $WPS_DIR"
  echo "        Clone o repositório antes de executar este script."
  exit 1
fi

mkdir -p "$ERA5_DIR"
cd "$WPS_DIR"

export JASPER=/dependencias/jasper
export JASPERINC=/dependencias/jasper/include
export JASPERLIB=/dependencias/jasper/lib
export NETCDF=/dependencias/netcdf
export PNETCDF=/dependencias/pnetcdf
export PIO=/dependencias/pio
export LD_LIBRARY_PATH="/dependencias/zlib/lib:/dependencias/hdf5/lib:/dependencias/netcdf/lib:/dependencias/pio/lib:/dependencias/pnetcdf/lib:/dependencias/metis/lib:/dependencias/jasper/lib:${LD_LIBRARY_PATH:-}"
export PATH="/dependencias/netcdf/bin:/dependencias/pio/bin:/dependencias/pnetcdf/bin:/dependencias/metis/bin:/dependencias/jasper/bin:${PATH}"

cat > ./namelist.wps <<'EOF'
&share
 wrf_core = 'ARW',
 max_dom = 1,
 start_date = '2025-01-01_00:00:00',
 end_date   = '2025-01-03_18:00:00',
 interval_seconds = 21600,
 io_form_geogrid = 2,
/

&geogrid
 parent_id         = 1,
 parent_grid_ratio = 1,
 i_parent_start    = 1,
 j_parent_start    = 1,
 e_we              = 100,
 e_sn              = 100,
 geog_data_res     = 'default',
 dx                = 30000,
 dy                = 30000,
 map_proj          = 'lat-lon',
 ref_lat           = -17.0,
 ref_lon           = -49.5,
 truelat1          = -17.0,
 truelat2          = -17.0,
 stand_lon         = -49.5,
 geog_data_path    = '/build/WPS/geog',
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/

&metgrid
 fg_name = 'FILE'
 io_form_metgrid = 2,
/
EOF

if [ -f /dados/era5/baixar_era5.py ] && [ ! -f "$ERA5_DIR/era5_pressure_levels.grib" ] && [ ! -f "$ERA5_DIR/era5_single_levels.grib" ]; then
  echo "[INFO] Baixando dados ERA5 em $ERA5_DIR"
  python3 /dados/era5/baixar_era5.py || true
fi

if [ -f "$ERA5_DIR/era5_pressure_levels.grib" ] || [ -f "$ERA5_DIR/era5_single_levels.grib" ]; then
  echo "[INFO] Arquivos GRIB encontrados em $ERA5_DIR"
  ls -lh "$ERA5_DIR"/*.grib 2>/dev/null || true
else
  echo "[WARN] Nenhum arquivo GRIB encontrado."
  echo "       O download depende de credenciais CDS API válidas."
fi

if [ ! -f ./configure.wps ]; then
  echo "[INFO] A configuração do WPS ainda não foi gerada."
  echo "       Execute: ./configure"
  echo "       Em seguida: ./compile"
  exit 0
fi

if [ ! -x ./ungrib.exe ]; then
  echo "[INFO] WPS pronto para build."
  echo "       Execute: ./compile"
  exit 0
fi

echo "[INFO] WPS e ungrib parecem estar prontos."
ls -lh ./ungrib.exe ./geogrid.exe ./metgrid.exe 2>/dev/null || true

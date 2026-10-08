#!/usr/bin/env python3
"""ERA5 global para a condição inicial; não fornece atualizações SST ou LBC."""
from datetime import datetime
import os
from pathlib import Path

PRESSURE_LEVELS = '1 2 3 5 7 10 20 30 50 70 100 125 150 175 200 225 250 300 350 400 450 500 550 600 650 700 750 775 800 825 850 875 900 925 950 975 1000'.split()
PRESSURE_VARIABLES = ['geopotential', 'relative_humidity', 'temperature', 'u_component_of_wind', 'v_component_of_wind']
SURFACE_VARIABLES = [
    '10m_u_component_of_wind', '10m_v_component_of_wind',
    '2m_temperature', '2m_dewpoint_temperature',
    'mean_sea_level_pressure', 'surface_pressure',
    'sea_surface_temperature', 'skin_temperature', 'sea_ice_cover', 'snow_depth',
    *[f'soil_temperature_level_{i}' for i in range(1, 5)],
    *[f'volumetric_soil_water_layer_{i}' for i in range(1, 5)],
]


def request_for(start_time, surface):
    date = datetime.strptime(start_time, '%Y-%m-%d_%H:%M:%S')
    request = {
        'product_type': ['reanalysis'],
        'variable': SURFACE_VARIABLES if surface else PRESSURE_VARIABLES,
        'year': [date.strftime('%Y')], 'month': [date.strftime('%m')],
        'day': [date.strftime('%d')], 'time': [date.strftime('%H:%M')],
        'area': [90, -180, -90, 180],
        'data_format': 'grib', 'download_format': 'unarchived',
    }
    if not surface:
        request['pressure_level'] = PRESSURE_LEVELS
    return request


def main():
    import cdsapi
    start_time = os.environ['START_TIME']
    target = Path(os.environ['ERA5_DIR']) / start_time[:13]
    target.mkdir(parents=True, exist_ok=True)
    client = cdsapi.Client()
    for surface in (False, True):
        kind = 'single' if surface else 'pressure'
        output = target / f'era5_{kind}_levels.grib'
        if output.is_file() and output.stat().st_size:
            print(f'Preservando arquivo existente: {output}')
            continue
        temporary = output.with_suffix('.grib.download')
        client.retrieve(f'reanalysis-era5-{kind}-levels', request_for(start_time, surface), str(temporary))
        if not temporary.is_file() or not temporary.stat().st_size:
            raise ValueError(f'Download não produziu arquivo: {temporary}')
        temporary.replace(output)
    print(f'ERA5 em {target}')


if __name__ == '__main__':
    main()

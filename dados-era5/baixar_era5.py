```python
import cdsapi

client = cdsapi.Client()

# =========================================================
# ERA5 - PRESSURE LEVELS
# =========================================================

dataset = 'reanalysis-era5-pressure-levels'

request = {
    'product_type': ['reanalysis'],
    'variable': [
        'geopotential',
        'relative_humidity',
        'temperature',
        'u_component_of_wind',
        'v_component_of_wind',
    ],
    'year': ['2025'],
    'month': ['01'],
    'day': ['01', '02', '03'],
    'time': [
        '00:00',
        '06:00',
        '12:00',
        '18:00',
    ],

    # Níveis de pressão do ERA5
    # Cobertura vertical muito maior que os 6 níveis anteriores
    'pressure_level': [
        '1',
        '2',
        '3',
        '5',
        '7',
        '10',
        '20',
        '30',
        '50',
        '70',
        '100',
        '125',
        '150',
        '175',
        '200',
        '225',
        '250',
        '300',
        '350',
        '400',
        '450',
        '500',
        '550',
        '600',
        '650',
        '700',
        '750',
        '775',
        '800',
        '825',
        '850',
        '875',
        '900',
        '925',
        '950',
        '975',
        '1000',
    ],

    'data_format': 'grib',
    'download_format': 'unarchived',

    # Norte, Oeste, Sul, Leste
    'area': [-14.0, -53.0, -19.5, -46.0],
}

target = 'era5_pressure_levels.grib'

client.retrieve(dataset, request, target)


# =========================================================
# ERA5 - SINGLE LEVELS
# =========================================================

dataset = 'reanalysis-era5-single-levels'

request = {
    'product_type': ['reanalysis'],
    'variable': [
        '10m_u_component_of_wind',
        '10m_v_component_of_wind',
        '2m_temperature',
        '2m_dewpoint_temperature',
        'mean_sea_level_pressure',
        'surface_pressure',
        'total_precipitation',
    ],
    'year': ['2025'],
    'month': ['01'],
    'day': ['01', '02', '03'],
    'time': [
        '00:00',
        '06:00',
        '12:00',
        '18:00',
    ],

    'data_format': 'grib',
    'download_format': 'unarchived',

    # Norte, Oeste, Sul, Leste
    'area': [-14.0, -53.0, -19.5, -46.0],
}

target = 'era5_single_levels.grib'

client.retrieve(dataset, request, target)
```

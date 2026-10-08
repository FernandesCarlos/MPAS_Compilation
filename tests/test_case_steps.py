import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
STEPS = ROOT / 'scripts/case'


class CaseStepsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.directory = Path(self.tmp.name)

    def run_step(self, name, **env):
        return subprocess.run(['bash', str(STEPS / name)], text=True, capture_output=True,
                              env={**os.environ, 'RUN_DIR': str(self.directory), **env})

    def test_init_config_preserves_other_options_and_streams(self):
        nl = self.directory / 'namelist.init_atmosphere'
        nl.write_text('&nhyd_model\n config_init_case = 1, ! comment\n config_custom = 123,\n/\n')
        xml = self.directory / 'streams.init_atmosphere'
        xml.write_text('<streams><immutable_stream name="input" filename_template="old.nc"/><immutable_stream name="output" filename_template="old-out.nc"/><immutable_stream name="surface"/><immutable_stream name="lbc"/></streams>')
        for _ in range(2):
            result = self.run_step('04_configurar_init.sh')
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('config_custom = 123', nl.read_text())
        self.assertEqual(nl.read_text().count('config_init_case'), 1)
        self.assertTrue(list(self.directory.glob('namelist.init_atmosphere.bak.*')))
        streams = ET.parse(xml).getroot()
        self.assertEqual(len(streams), 4)
        self.assertEqual(streams.find("./immutable_stream[@name='input']").get('filename_template'), 'x1.10242.static.nc')

    def test_atmosphere_config_and_missing_stream_are_atomic(self):
        nl = self.directory / 'namelist.atmosphere'
        original = '&nhyd_model\n config_dt=720.0,\n/\n'
        nl.write_text(original)
        xml = self.directory / 'streams.atmosphere'
        xml.write_text('<streams><immutable_stream name="input"/></streams>')
        result = self.run_step('06_configurar_atmosfera.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(nl.read_text(), original)
        xml.write_text('<streams><immutable_stream name="input"/><stream name="output"><file name="list"/></stream><stream name="diagnostics"/></streams>')
        result = self.run_step('06_configurar_atmosfera.sh', START_TIME='2020-02-03_06:00:00', NP='8')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('2020-02-03_06:00:00', nl.read_text())
        streams = ET.parse(xml).getroot()
        self.assertIsNotNone(streams.find("./stream[@name='output']/file"))
        self.assertEqual(streams.find("./stream[@name='output']").get('output_interval'), '00:30:00')

    def test_converter_requires_executable(self):
        result = self.run_step('03_converter_era5.sh', WPS_DIR=str(self.directory / 'missing'))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('ungrib.exe', result.stderr)

    def test_malformed_namelist_is_not_rewritten(self):
        nl = self.directory / 'namelist.atmosphere'
        original = '&nhyd_model\n config_dt=720.0,\n&physics\n config_sst_update=.true.,\n/\n'
        nl.write_text(original)
        xml = self.directory / 'streams.atmosphere'
        original_xml = '<streams><immutable_stream name="input"/><stream name="output"/><stream name="diagnostics"/></streams>'
        xml.write_text(original_xml)
        result = self.run_step('06_configurar_atmosfera.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(nl.read_text(), original)
        self.assertEqual(xml.read_text(), original_xml)
        self.assertEqual(list(self.directory.glob('*.bak.*')), [])

    def test_era5_request_matches_start_and_global_area(self):
        spec = importlib.util.spec_from_file_location('era5', STEPS / 'download_era5.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        req = module.request_for('2020-02-03_06:00:00', surface=False)
        self.assertEqual(req['year'], ['2020'])
        self.assertEqual(req['time'], ['06:00'])
        self.assertEqual(req['area'], [90, -180, -90, 180])
        self.assertEqual(len(req['pressure_level']), 37)
        surface = module.request_for('2020-02-03_06:00:00', surface=True)
        self.assertIn('soil_temperature_level_4', surface['variable'])
        self.assertIn('volumetric_soil_water_layer_4', surface['variable'])

    def test_conversion_links_both_gribs_and_copies_intermediate(self):
        wps = self.directory / 'wps'
        wps.mkdir()
        exe = wps / 'ungrib.exe'
        exe.write_text("#!/bin/bash\nset -eu\ntest -s GRIBFILE.AAA\ntest -s GRIBFILE.AAB\ntest -s Vtable\nprintf 'intermediate' > 'ERA5:2025-01-01_00'\n")
        exe.chmod(0o755)
        vtable = wps / 'table'
        vtable.write_text('fixture')
        era = self.directory / 'era5'
        hour = era / '2025-01-01_00'
        hour.mkdir(parents=True)
        for kind in ('pressure', 'single'):
            (hour / f'era5_{kind}_levels.grib').write_bytes(b'GRIB' + (20).to_bytes(3, 'big') + b'\1' + b'\0' * 8 + b'7777')
        result = self.run_step('03_converter_era5.sh', WPS_DIR=str(wps), ERA5_DIR=str(era), WPS_VTABLE=str(vtable))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.directory / 'ERA5:2025-01-01_00').read_text(), 'intermediate')
        # Uma segunda execução sem saída nova precisa falhar, mesmo com a anterior presente.
        exe.write_text('#!/bin/bash\nexit 0\n')
        result = self.run_step('03_converter_era5.sh', WPS_DIR=str(wps), ERA5_DIR=str(era), WPS_VTABLE=str(vtable))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('ungrib não gerou', result.stderr)
        work = self.directory / 'wps_2025-01-01_00'
        self.assertFalse((work / 'ERA5:2025-01-01_00').exists())
        self.assertTrue(list(work.glob('ERA5:2025-01-01_00.bak.*')))



if __name__ == '__main__':
    unittest.main()

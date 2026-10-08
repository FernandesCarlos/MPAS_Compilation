import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STEPS = ROOT / 'scripts/case'


class WpsSetupTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.wps = self.root / 'wps'
        self.wps.mkdir()
        tables = self.wps / 'ungrib/Variable_Tables'
        tables.mkdir(parents=True)
        (tables / 'Vtable.ERA-interim.pl').write_text('GRIB1 table fixture')
        (self.wps / 'arch').mkdir()
        (self.wps / 'arch/configure.defaults').write_text('#ARCH Linux x86_64 Intel # serial dmpar\nSFC=ifort\n#ARCH Linux x86_64 gfortran # serial dmpar\nSFC=gfortran\n')
        self.bindir = self.root / 'bin'
        self.bindir.mkdir()
        for name in ('gcc', 'gfortran', 'csh', 'perl', 'make', 'cmake'):
            self.script(self.bindir / name, 'exit 0')
        self.netcdf = self.root / 'netcdf'
        (self.netcdf / 'include').mkdir(parents=True)
        (self.netcdf / 'include/netcdf.inc').write_text('fixture')

    def script(self, path, code):
        path.write_text('#!/bin/bash\nset -eu\n' + code + '\n')
        path.chmod(0o755)

    def run_setup(self):
        return subprocess.run(['bash', str(STEPS / '02a_preparar_wps.sh')],
            env={**os.environ, 'RUN_DIR': str(self.root / 'run'), 'WPS_DIR': str(self.wps),
                 'NETCDF': str(self.netcdf), 'PATH': f'{self.bindir}:{os.environ["PATH"]}'},
            capture_output=True, text=True)

    def setup_build(self, broken=False):
        self.script(self.wps / 'clean', 'rm -f ungrib.exe util/*.exe configure.wps')
        self.script(self.wps / 'configure', '''read option
test "$option" = 3
test "$1" = --nowrf
test "$2" = --build-grib2-libs
printf 'SFC = gfortran\n' > configure.wps''')
        build = '''mkdir -p util
if [[ "$1" == ungrib ]]; then output=ungrib.exe; else output="util/$1.exe"; fi
printf '#!/bin/bash\\nexit 0\\n' > "$output"
chmod +x "$output"'''
        self.script(self.wps / 'compile', 'exit 0' if broken else build)

    def test_compile_and_prepare_table_for_next_process(self):
        self.setup_build()
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in ('ungrib.exe', 'util/g1print.exe', 'util/g2print.exe', 'util/rd_intermediate.exe'):
            self.assertTrue((self.wps / name).is_file())
        table = self.root / 'run/Vtable.ERA5'
        self.assertEqual(table.read_text(), 'GRIB1 table fixture')

    def test_compile_success_without_binary_is_failure(self):
        self.setup_build(broken=True)
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('ungrib.exe', result.stderr)

    def test_grib2_does_not_use_grib1_table(self):
        spec = importlib.util.spec_from_file_location('wps_tools', STEPS / 'wps_tools.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        grib = self.root / 'test.grib'
        grib.write_bytes(b'GRIB\0\0\0\2' + (20).to_bytes(8, 'big') + b'7777')
        table = self.wps / 'ungrib/Variable_Tables/Vtable.ERA-interim.pl'
        with self.assertRaisesRegex(ValueError, 'GRIB2'):
            module.check_table(table, [grib])
        table.write_text('# This GRIB1 table has no GRIB2 support')
        with self.assertRaisesRegex(ValueError, 'GRIB2'):
            module.check_table(table, [grib])
        table.write_text('GRIB1|Level|From|To|metgrid|metgrid|metgrid|GRIB2|GRIB2|GRIB2|GRIB2|\n'
                         'Param|Type|Level1|Level2|Name|Units|Description|Discp|Catgy|Param|Level|\n'
                         '11|100|*||TT|K|Temperature|0|0|0|100|\n')
        module.check_table(table, [grib])


if __name__ == '__main__':
    unittest.main()

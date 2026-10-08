import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ScriptsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='mpas test ')
        self.addCleanup(self.tmp.cleanup)
        self.run_dir = Path(self.tmp.name)

    def call(self, *args, **env):
        return subprocess.run(['bash', str(ROOT / 'scripts/mpas.sh'), *args],
                              env={**os.environ, 'RUN_DIR': str(self.run_dir), **env},
                              text=True, capture_output=True)

    def case(self):
        (self.run_dir / 'namelist.atmosphere').write_text("&decomposition\n config_block_decomp_file_prefix = 'mesh.graph.info.part.'\n/\n")
        (self.run_dir / 'streams.atmosphere').write_text('<streams><immutable_stream name="input" type="input" filename_template="init.nc"/></streams>')
        (self.run_dir / 'init.nc').write_text('fixture')
        (self.run_dir / 'mesh.graph.info.part.4').write_text('0\n1\n2\n3\n')
        exe = self.run_dir / 'atmosphere_model'
        exe.write_text('#!/bin/bash\nexit 0\n')
        exe.chmod(0o755)

    def test_invalid_ranks(self):
        r = self.call('check', 'atmosphere', NP='0')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('NP', r.stderr)

    def test_missing_case_stops_before_mpi(self):
        r = self.call('check', 'atmosphere')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('namelist.atmosphere', r.stderr)

    def test_ready_case_and_missing_partition(self):
        self.case()
        self.assertEqual(self.call('check', 'atmosphere').returncode, 0)
        (self.run_dir / 'mesh.graph.info.part.4').unlink()
        r = self.call('check', 'atmosphere')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('mesh.graph.info.part.4', r.stderr)

    def test_missing_input_and_stream_list(self):
        self.case()
        (self.run_dir / 'init.nc').unlink()
        self.assertNotEqual(self.call('check', 'atmosphere').returncode, 0)
        (self.run_dir / 'init.nc').write_text('fixture')
        (self.run_dir / 'streams.atmosphere').write_text('<streams><immutable_stream name="input" type="input" filename_template="init.nc"/><stream name="output" type="output"><file name="stream_list.atmosphere.output"/></stream></streams>')
        r = self.call('check', 'atmosphere')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('stream_list', r.stderr)

    def test_run_propagates_mpi_failure(self):
        self.case()
        mpi = self.run_dir / 'mpirun'
        mpi.write_text('#!/bin/bash\nexit 17\n')
        mpi.chmod(0o755)
        r = self.call('run', PATH=f'{self.run_dir}:{os.environ["PATH"]}')
        self.assertEqual(r.returncode, 17)

    def test_initialization_stage_guards(self):
        exe = self.run_dir / 'init_atmosphere_model'
        exe.write_text('#!/bin/bash\nexit 0\n')
        exe.chmod(0o755)
        (self.run_dir / 'grid.nc').write_text('fixture')
        (self.run_dir / 'geog').mkdir()
        (self.run_dir / 'streams.init_atmosphere').write_text('<streams><immutable_stream name="input" filename_template="grid.nc"/></streams>')
        nl = self.run_dir / 'namelist.init_atmosphere'
        nl.write_text("config_init_case=7, config_static_interp=.true., config_met_interp=.false., config_geog_data_path='geog'")
        self.assertEqual(self.call('check', 'static', NP='1').returncode, 0)
        self.assertNotEqual(self.call('check', 'init', NP='1').returncode, 0)
        nl.write_text("config_init_case=7, config_static_interp=.false., config_met_interp=.true., config_met_prefix='ERA5', config_start_time='2025-01-01_00:00:00'")
        self.assertNotEqual(self.call('check', 'init', NP='1').returncode, 0)
        (self.run_dir / 'ERA5:2025-01-01_00').write_text('fixture')
        self.assertEqual(self.call('check', 'init', NP='1').returncode, 0)

    def test_restart_rejected(self):
        self.case()
        nl = self.run_dir / 'namelist.atmosphere'
        nl.write_text(nl.read_text() + '\nconfig_do_restart=.true.\n')
        r = self.call('check', 'atmosphere')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('restart', r.stderr)

    def test_initialization_requires_matching_nonempty_file(self):
        self.test_initialization_stage_guards()
        valid = self.run_dir / 'ERA5:2025-01-01_00'
        valid.unlink()
        (self.run_dir / 'ERA5:1999-01-01_00').write_text('wrong date')
        valid.mkdir()
        self.assertNotEqual(self.call('check', 'init', NP='1').returncode, 0)

    def test_docker_mounts_paths_with_spaces(self):
        bindir = self.run_dir / 'bin'
        bindir.mkdir()
        docker = bindir / 'docker'
        trace = self.run_dir / 'args'
        docker.write_text('''#!/usr/bin/env python3
import json, os, sys
if sys.argv[1:3] == ['container', 'inspect']: sys.exit(1)
if sys.argv[1] == 'run':
    open(os.environ['TRACE'], 'w').write(json.dumps(sys.argv[1:]))
''')
        docker.chmod(0o755)
        result = subprocess.run(['bash', str(ROOT / 'scripts/docker_mpas.sh'), 'shell'],
            env={**os.environ, 'PATH': f'{bindir}:{os.environ["PATH"]}',
                 'RUN_DIR_HOST': str(self.run_dir / 'my run'),
                 'DATA_DIR_HOST': str(self.run_dir / 'my data'), 'TRACE': str(trace)},
            text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        import json
        args = json.loads(trace.read_text())
        self.assertIn(f'type=bind,source={self.run_dir}/my run,target=/mpas/run', args)
        self.assertNotIn('--rm', args)

    def test_build_preserves_config_and_copies_both_cores(self):
        source = self.run_dir / 'source'
        source.mkdir()
        (source / 'Makefile').write_text('fixture')
        tables = source / 'src/core_atmosphere/physics/physics_wrf/files'
        tables.mkdir(parents=True)
        (tables / 'LANDUSE.TBL').write_text('table')
        bindir = self.run_dir / 'bin'
        bindir.mkdir()
        make = bindir / 'make'
        make.write_text('''#!/bin/bash
set -eu
if [[ "$1" == clean ]]; then rm -f *_model namelist.* streams.* stream_list.*; exit 0; fi
core=atmosphere
for arg in "$@"; do [[ "$arg" != CORE=* ]] || core="${arg#CORE=}"; done
printf '#!/bin/bash\\nexit 0\\n' > "${core}_model"
chmod +x "${core}_model"
echo defaults > "namelist.$core"
echo defaults > "streams.$core"
echo fields > "stream_list.$core.output"
''')
        make.chmod(0o755)
        (self.run_dir / 'namelist.atmosphere').write_text('my configuration')
        r = self.call('compile', MPAS_SOURCE=str(source), JOBS='2', PATH=f'{bindir}:{os.environ["PATH"]}')
        self.assertEqual(r.returncode, 0, r.stderr)
        for core in ['init_atmosphere', 'atmosphere']:
            self.assertTrue((self.run_dir / f'{core}_model').is_file())
            self.assertTrue((self.run_dir / f'stream_list.{core}.output').is_file())
        self.assertEqual((self.run_dir / 'namelist.atmosphere').read_text(), 'my configuration')
        self.assertEqual((self.run_dir / 'LANDUSE.TBL').read_text(), 'table')


if __name__ == '__main__':
    unittest.main()

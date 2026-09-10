import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "validate" / "validate_outputs.py"


class ValidateOutputsTest(unittest.TestCase):
    def test_missing_file_reports_fail(self):
        proc = subprocess.run(
            [sys.executable, str(SCRIPT), "/definitely/missing/file.nc"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("FAIL", proc.stdout + proc.stderr)
        self.assertIn("file.nc", proc.stdout + proc.stderr)

    @unittest.skipUnless(__import__("importlib").util.find_spec("netCDF4"), "netCDF4 not installed")
    def test_finite_netcdf_passes_and_nan_fails(self):
        import netCDF4
        import numpy as np

        with tempfile.TemporaryDirectory() as td:
            td = pathlib.Path(td)
            good = td / "good.nc"
            with netCDF4.Dataset(good, "w") as ds:
                ds.createDimension("Time", 1)
                ds.createDimension("nCells", 2)
                v = ds.createVariable("t2m", "f4", ("Time", "nCells"))
                v[:] = [[280.0, 281.0]]
            proc = subprocess.run(
                [sys.executable, str(SCRIPT), str(good), "--require-var", "t2m", "--require-time"],
                text=True,
                capture_output=True,
            )
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            self.assertIn("PASS", proc.stdout)

            bad = td / "bad.nc"
            with netCDF4.Dataset(bad, "w") as ds:
                ds.createDimension("Time", 1)
                ds.createDimension("nCells", 2)
                v = ds.createVariable("t2m", "f4", ("Time", "nCells"))
                v[:] = [[280.0, np.nan]]
            proc = subprocess.run(
                [sys.executable, str(SCRIPT), str(bad), "--require-var", "t2m"],
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("FAIL", proc.stdout + proc.stderr)


if __name__ == "__main__":
    unittest.main()

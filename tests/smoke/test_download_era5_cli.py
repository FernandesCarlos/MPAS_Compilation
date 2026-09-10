import pathlib
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class DownloadEra5CliTest(unittest.TestCase):
    def test_dry_run_describes_both_datasets_without_credentials(self):
        proc = subprocess.run(
            [sys.executable, str(ROOT / "scripts/data/download_era5.py"), "--dry-run"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("reanalysis-era5-pressure-levels", proc.stdout)
        self.assertIn("era5-pressure-levels.grib", proc.stdout)
        self.assertIn("reanalysis-era5-single-levels", proc.stdout)
        self.assertIn("era5-single-levels.grib", proc.stdout)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Compatibilidade: delega o download ERA5 ao pipeline oficial."""
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
runpy.run_path(str(ROOT / "scripts" / "data" / "download_era5.py"), run_name="__main__")

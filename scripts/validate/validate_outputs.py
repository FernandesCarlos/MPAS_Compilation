#!/usr/bin/env python3
"""Valida estruturalmente saídas NetCDF do caso MPAS sem inferir forecast skill."""
from __future__ import annotations

import argparse
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Valida integridade e valores finitos em NetCDFs MPAS."
    )
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument(
        "--require-var",
        action="append",
        default=[],
        help="variável obrigatória (pode repetir)",
    )
    parser.add_argument(
        "--require-time",
        action="store_true",
        help="exige dimensão/variável temporal",
    )
    return parser.parse_args()


def fail(path: Path, reason: str) -> bool:
    print(f"FAIL {path}: {reason}")
    return False


def validate_one(path: Path, required_vars: list[str], require_time: bool) -> bool:
    if not path.is_file() or path.stat().st_size == 0:
        return fail(path, "arquivo ausente ou vazio")

    try:
        import netCDF4  # type: ignore
        import numpy as np
    except ImportError as exc:
        return fail(path, f"dependência Python ausente: {exc.name}")

    try:
        ds = netCDF4.Dataset(path, "r")
    except Exception as exc:
        return fail(path, f"não foi possível abrir NetCDF: {exc}")

    ok = True
    try:
        zero_dims = [
            name
            for name, dim in ds.dimensions.items()
            if len(dim) == 0 and not dim.isunlimited()
        ]
        if zero_dims:
            fail(path, "dimensões vazias: " + ", ".join(zero_dims))
            ok = False

        missing = [name for name in required_vars if name not in ds.variables]
        if missing:
            fail(path, "variáveis obrigatórias ausentes: " + ", ".join(missing))
            ok = False

        if require_time:
            has_time = (
                "Time" in ds.dimensions
                or "Time" in ds.variables
                or "xtime" in ds.variables
            )
            if not has_time:
                fail(path, "coordenada temporal Time/xtime ausente")
                ok = False

        for name, var in ds.variables.items():
            dtype = getattr(var, "dtype", None)
            if dtype is None or getattr(dtype, "kind", "") not in "fciub":
                continue
            if getattr(var, "size", 0) == 0:
                continue

            try:
                if var.ndim == 0:
                    chunks = [var[...]]
                else:
                    step = max(1, min(64, var.shape[0]))
                    chunks = (
                        var[i : i + step, ...]
                        for i in range(0, var.shape[0], step)
                    )
                for chunk in chunks:
                    arr = np.ma.asarray(chunk)
                    values = (
                        arr.compressed()
                        if np.ma.isMaskedArray(arr)
                        else np.asarray(arr).ravel()
                    )
                    if values.size and not np.isfinite(values).all():
                        fail(path, f"NaN/Inf encontrado em {name}")
                        ok = False
                        break
            except Exception as exc:
                fail(path, f"erro ao ler variável {name}: {exc}")
                ok = False
    finally:
        ds.close()

    if ok:
        print(f"PASS {path}")
    return ok


def main() -> int:
    args = parse_args()
    results = [
        validate_one(path, args.require_var, args.require_time)
        for path in args.files
    ]
    return 0 if all(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())

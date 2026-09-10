#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CASE = REPO_ROOT / "cases" / "first-global-240km"
DEFAULT_DATA = REPO_ROOT / "data" / "first-global-240km" / "era5"


def load_definition(path: Path) -> dict:
    with path.open(encoding="utf-8") as fh:
        doc = json.load(fh)
    for key in ("dataset", "output_filename", "request"):
        if key not in doc:
            raise ValueError(f"{path}: campo obrigatório ausente: {key}")
    return doc


def credential_path() -> Path:
    return Path(os.environ.get("CDSAPI_RC", Path.home() / ".cdsapirc"))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Baixa ERA5 para a baseline global MPAS de 2014-09-10 00 UTC."
    )
    parser.add_argument("--case-root", type=Path, default=DEFAULT_CASE)
    parser.add_argument("--data-root", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--force", action="store_true", help="refaz downloads existentes")
    parser.add_argument("--dry-run", action="store_true", help="mostra o plano sem acessar o CDS")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    definitions = [
        load_definition(args.case_root / "era5" / "pressure-levels.json"),
        load_definition(args.case_root / "era5" / "single-levels.json"),
    ]

    args.data_root.mkdir(parents=True, exist_ok=True)
    for doc in definitions:
        target = args.data_root / doc["output_filename"]
        print(f"[ERA5] {doc['dataset']} -> {target}")
        if args.dry_run:
            continue
        if target.is_file() and target.stat().st_size > 0 and not args.force:
            print(f"[SKIP] arquivo já existe: {target}")
            continue

        rc = credential_path()
        if not rc.is_file() or rc.stat().st_size == 0:
            print(f"[ERROR] credencial CDS não encontrada: {rc}", file=sys.stderr)
            return 2

        try:
            import cdsapi
        except ImportError:
            print("[ERROR] pacote Python 'cdsapi' não está instalado", file=sys.stderr)
            return 3

        cdsapi.Client().retrieve(doc["dataset"], doc["request"], str(target))
        if not target.is_file() or target.stat().st_size == 0:
            print(f"[ERROR] download não produziu arquivo válido: {target}", file=sys.stderr)
            return 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

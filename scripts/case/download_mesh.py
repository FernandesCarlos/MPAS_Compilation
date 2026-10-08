#!/usr/bin/env python3
import os
from pathlib import Path
import shutil
import tarfile
import tempfile
from urllib.request import urlretrieve


def main():
    target = Path(os.environ['RUN_DIR']).resolve()
    target.mkdir(parents=True, exist_ok=True)
    mesh = os.environ['MESH']
    archives = {
        f'{mesh}.tar.gz': [f'{mesh}.grid.nc', f'{mesh}.graph.info'],
        f'{mesh}_static.tar.gz': [f'{mesh}.static.nc'],
    }
    for archive, files in archives.items():
        missing = [name for name in files if not (target / name).is_file() or not (target / name).stat().st_size]
        if not missing:
            print(f'Entradas já disponíveis: {", ".join(files)}')
            continue
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            print(f'Baixando {archive}')
            urlretrieve(f'https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/{archive}', root / archive)
            unpack = root / 'unpack'
            unpack.mkdir()
            with tarfile.open(root / archive) as stream:
                stream.extractall(unpack, filter='data')
            for name in missing:
                found = [p for p in unpack.rglob(name) if p.is_file() and p.stat().st_size]
                if len(found) != 1:
                    raise ValueError(f'Esperado exatamente um arquivo {name} em {archive}')
                shutil.copyfile(found[0], target / name)
    print(f'Malha e campos estáticos em {target}')


if __name__ == '__main__':
    main()

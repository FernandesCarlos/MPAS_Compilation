#!/usr/bin/env python3
"""Seleção do menu WPS 4.5 e bloqueio de Vtable GRIB1 para arquivos GRIB2."""
from pathlib import Path
import platform
import sys


def configure_option(path):
    # Reproduz o menu de arch/Config.pl com --build-grib2-libs:
    # plataformas serial/dmpar, filtradas por sistema e arquitetura.
    choices = []
    for line in Path(path).read_text().splitlines():
        if not line.startswith('#ARCH'):
            continue
        if platform.system() not in line or platform.machine() not in line:
            continue
        label = line[6:].split('#')[0].strip()
        if label.startswith('NULL'):
            continue
        for mode in ('serial', 'dmpar'):
            if mode in line:
                choices.append((label, mode))
    for number, (label, mode) in enumerate(choices, 1):
        if 'gfortran' in label.lower() and mode == 'serial':
            return number
    raise ValueError('Não foi encontrada a opção gfortran serial para esta arquitetura no WPS.')


def editions(path):
    result = set()
    with Path(path).open('rb') as stream:
        stream.seek(0, 2)
        size = stream.tell()
        position = 0
        while position < size:
            stream.seek(position)
            header = stream.read(16)
            if len(header) < 8 or header[:4] != b'GRIB':
                raise ValueError(f'Arquivo não é um fluxo GRIB reconhecido: {path}, posição {position}')
            edition = header[7]
            if edition == 1:
                length = int.from_bytes(header[4:7], 'big')
                minimum = 12
            elif edition == 2 and len(header) == 16:
                length = int.from_bytes(header[8:16], 'big')
                minimum = 20
            else:
                raise ValueError(f'Edição GRIB não suportada: {edition} em {path}')
            if length < minimum or position + length > size:
                raise ValueError(f'Mensagem GRIB incompleta em {path}')
            stream.seek(position + length - 4)
            if stream.read(4) != b'7777':
                raise ValueError(f'Terminador GRIB inválido em {path}')
            result.add(edition)
            position += length
    if not result:
        raise ValueError(f'Arquivo GRIB vazio: {path}')
    return result


def has_grib2_codes(table):
    header_found = False
    for line in Path(table).read_text().splitlines():
        if line.lstrip().startswith('#'):
            continue
        columns = [part.strip().upper() for part in line.split('|')]
        if len(columns) < 11:
            continue
        if columns[7:11] == ['GRIB2'] * 4:
            header_found = True
        elif header_found and all(value.isdigit() for value in columns[7:11]):
            return True
    return False


def check_table(table, files):
    found = set().union(*(editions(path) for path in files))
    if 2 in found and not has_grib2_codes(table):
        raise ValueError('Os dados contêm GRIB2, mas a Vtable não possui colunas GRIB2 com códigos preenchidos. Defina WPS_VTABLE para uma tabela compatível e execute 02a_preparar_wps.sh novamente.')
    print(f'Edições encontradas: {sorted(found)}. Confira também os códigos e campos da Vtable com g1print/g2print.')


if __name__ == '__main__':
    try:
        if sys.argv[1] == 'option':
            print(configure_option(sys.argv[2]))
        elif sys.argv[1] == 'check-table':
            check_table(sys.argv[2], sys.argv[3:])
        else:
            raise ValueError('Comando desconhecido')
    except (OSError, ValueError) as error:
        sys.exit(f'ERRO: {error}')

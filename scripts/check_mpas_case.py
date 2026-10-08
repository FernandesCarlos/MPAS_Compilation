#!/usr/bin/env python3
"""Verificações de arquivos e opções essenciais; não valida NetCDF nem física."""
import os
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def fail(message):
    raise ValueError(message)


def check(directory, stage, ranks):
    if stage not in ('static', 'init', 'atmosphere'):
        fail('Etapa deve ser static, init ou atmosphere.')
    directory = Path(directory).resolve()
    core = 'atmosphere' if stage == 'atmosphere' else 'init_atmosphere'

    def require(filename):
        path = directory / filename
        if not path.is_file() or path.stat().st_size == 0:
            fail(f'Arquivo ausente ou vazio: {path}')
        return path

    namelist = require(f'namelist.{core}').read_text()
    # Remove comentários Fortran fora de strings, preservando ! dentro de caminhos.
    namelist = re.sub(r"('(?:[^']|'')*'|\"(?:[^\"]|\"\")*\")|![^\n]*", lambda m: m.group(1) or '', namelist)

    def option(key):
        matches = re.findall(r'\b' + re.escape(key) + r'\s*=\s*(\x27[^\x27]*\x27|"[^"]*"|[^,\s/]+)', namelist, re.I)
        if len(matches) > 1:
            fail(f'Opção duplicada no namelist: {key}')
        return matches[0].strip("\x27\"") if matches else None

    def flag(key, expected):
        value = option(key)
        if value is None or value.lower() != expected:
            fail(f'Para {stage}, ajuste {key} = {expected} no namelist.')

    if stage == 'atmosphere' and (option('config_do_restart') or '.false.').lower() != '.false.':
        fail('Este fluxo exige config_do_restart = .false.; restart não é suportado.')

    streams = ET.parse(require(f'streams.{core}')).getroot()
    executable = require(f'{core}_model')
    if not os.access(executable, os.X_OK):
        fail(f'Executável sem permissão de execução: {executable}')

    if ranks > 1:
        prefix = option('config_block_decomp_file_prefix')
        if not prefix:
            fail('Defina config_block_decomp_file_prefix no namelist (sem o número final).')
        part = require(f'{prefix}{ranks}')
        with part.open() as stream:
            for line in stream:
                value = line.strip()
                if not value.isdigit() or not 0 <= int(value) < ranks:
                    fail(f'Partição incompatível com NP={ranks}: {part}')

    inputs = [s for s in streams if s.get('name') == 'input']
    if len(inputs) != 1:
        fail('streams deve conter exatamente um stream chamado input.')
    for stream in streams:
        for item in stream.findall('file'):
            if item.get('name'):
                require(item.get('name'))
    filename = inputs[0].get('filename_template')
    if not filename:
        fail('Defina filename_template no stream input.')
    # Verifique o arquivo inicial exato quando o template contém data/hora.
    replacements = {'$Y': (0, 4), '$M': (5, 7), '$D': (8, 10),
                    '$h': (11, 13), '$m': (14, 16), '$s': (17, 19)}
    start = option('config_start_time') or ''
    if '$' in filename:
        if not re.fullmatch(r'\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}', start):
            fail('Template de entrada com data exige config_start_time explícito.')
        for token, (first, last) in replacements.items():
            filename = filename.replace(token, start[first:last])
        if '$' in filename:
            fail(f'Template não suportado pela verificação: {filename}')
    require(filename)

    if stage in ('static', 'init'):
        if option('config_init_case') != '7':
            fail('Estes comandos são para dados reais: configure config_init_case = 7.')
        flag('config_static_interp', '.true.' if stage == 'static' else '.false.')
        flag('config_met_interp', '.false.' if stage == 'static' else '.true.')
        if stage == 'static':
            geography = option('config_geog_data_path')
            if not geography or not (directory / geography).is_dir():
                fail('Configure config_geog_data_path para os dados geográficos extraídos.')
        else:
            prefix = option('config_met_prefix')
            if not prefix:
                fail('Defina config_met_prefix para os arquivos intermediários do WPS.')
            if not re.fullmatch(r'\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}', start):
                fail('Defina config_start_time explícito para a inicialização meteorológica.')
            require(f'{prefix}:{start[:13]}')
    print(f'Arquivos essenciais encontrados para {stage}, NP={ranks}.')
    print('Esta verificação não comprova integridade NetCDF, cobertura dos dados ou estabilidade numérica.')


if __name__ == '__main__':
    try:
        check(sys.argv[1], sys.argv[2], int(sys.argv[3]))
    except (ValueError, OSError, ET.ParseError) as exc:
        print(f'ERRO: {exc}', file=sys.stderr)
        sys.exit(1)

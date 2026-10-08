#!/usr/bin/env python3
"""Atualiza apenas opções do caso, com backup dos arquivos existentes."""
import os
from pathlib import Path
import re
import shutil
import sys
import time
import xml.etree.ElementTree as ET


def quoted(value):
    if any(c in value for c in "'\n\r"):
        raise ValueError('Valor inválido para string Fortran')
    return f"'{value}'"


def update_namelist(text, groups):
    # Os defaults do MPAS usam grupos terminados por / em uma linha própria.
    # Não modifique arquivos com grupos incompletos ou aninhados.
    active = None
    for number, line in enumerate(text.splitlines(), 1):
        clean = re.sub(r"('(?:[^']|'')*'|\"(?:[^\"]|\"\")*\")|![^\n]*", lambda m: m.group(1) or '', line)
        header = re.match(r'^\s*&([a-zA-Z_][a-zA-Z_0-9]*)\b', clean)
        if header:
            if active:
                raise ValueError(f'Falta / para o grupo {active} antes da linha {number}')
            active = header.group(1)
        elif re.match(r'^\s*/\s*$', clean):
            if not active:
                raise ValueError(f'Terminador / sem grupo na linha {number}')
            active = None
    if active:
        raise ValueError(f'Falta / para o grupo {active}')
    for group, values in groups.items():
        pattern = re.compile(r'^(\s*&' + re.escape(group) + r'\b)(.*?)(^\s*/)', re.M | re.S | re.I)
        matches = list(pattern.finditer(text))
        if len(matches) > 1:
            raise ValueError(f'Grupo duplicado: {group}')
        body = matches[0].group(2) if matches else '\n'
        for key, value in values.items():
            option = re.compile(r'(?m)^(\s*' + re.escape(key) + r'\s*=\s*)(\x27[^\x27]*\x27|"[^"]*"|[^,\s]+)', re.I)
            if len(option.findall(body)) > 1:
                raise ValueError(f'Opção duplicada: {key}')
            if option.search(body):
                body = option.sub(lambda m: m.group(1) + value, body)
            else:
                body = body.rstrip() + f'\n {key} = {value},\n'
        block = f'&{group}' + body + '/'
        if matches:
            match = matches[0]
            text = text[:match.start()] + block + text[match.end():]
        else:
            text = text.rstrip() + '\n\n' + block + '\n'
    return text


def configure(stage):
    if stage not in ('init', 'atmosphere'):
        raise ValueError('Etapa deve ser init ou atmosphere')
    target = Path(os.environ['RUN_DIR'])
    core = 'init_atmosphere' if stage == 'init' else 'atmosphere'
    nl = target / f'namelist.{core}'
    xml = target / f'streams.{core}'
    original = nl.read_text()
    # Faça todas as validações antes de modificar qualquer arquivo.
    root = ET.parse(xml).getroot()
    def stream(name):
        found = [s for s in root if s.get('name') == name]
        if len(found) != 1:
            raise ValueError(f'Esperado exatamente um stream {name} em {xml}')
        return found[0]

    mesh = os.environ['MESH']
    start = quoted(os.environ['START_TIME'])
    groups = {
        'nhyd_model': {'config_start_time': start},
        'decomposition': {'config_block_decomp_file_prefix': quoted(f'{mesh}.graph.info.part.')},
    }
    if stage == 'init':
        groups['nhyd_model']['config_init_case'] = '7'
        levels = int(os.environ['NVERTLEVELS'])
        if levels < 1:
            raise ValueError('NVERTLEVELS deve ser positivo')
        groups.update({
            'dimensions': {'config_nvertlevels': str(levels), 'config_nsoillevels': '4', 'config_nfglevels': '38', 'config_nfgsoillevels': '4'},
            'data_sources': {'config_met_prefix': quoted('ERA5'), 'config_use_spechumd': '.false.', 'config_noahmp_static': '.false.'},
            'vertical_grid': {'config_ztop': '30000.0', 'config_nsmterrain': '1', 'config_smooth_surfaces': '.true.'},
            'preproc_stages': {'config_static_interp': '.false.', 'config_native_gwd_static': '.false.', 'config_vertical_grid': '.true.', 'config_met_interp': '.true.', 'config_input_sst': '.false.', 'config_frac_seaice': '.true.'},
        })
        # Desative a etapa UGWP somente se a opção existe nesta versão.
        if re.search(r'\bconfig_native_gwd_gsl_static\s*=', original, re.I):
            groups['preproc_stages']['config_native_gwd_gsl_static'] = '.false.'
        stream('input').set('filename_template', f'{mesh}.static.nc')
        stream('output').set('filename_template', 'init.nc')
    else:
        dt = float(os.environ['DT'])
        if not 0 < dt < float('inf'):
            raise ValueError('DT deve ser finito e positivo')
        groups['nhyd_model'].update({'config_dt': str(dt), 'config_run_duration': quoted(os.environ['RUN_DURATION'])})
        groups.update({'restart': {'config_do_restart': '.false.'},
                       'limited_area': {'config_apply_lbcs': '.false.'},
                       'physics': {'config_physics_suite': quoted('mesoscale_reference'), 'config_sst_update': '.false.'}})
        stream('input').set('filename_template', 'init.nc')
        for name in ('output', 'diagnostics'):
            stream(name).set('output_interval', os.environ['OUTPUT_INTERVAL'])
    updated = update_namelist(original, groups)
    ET.indent(root, space='  ')
    xml_text = ET.tostring(root, encoding='unicode') + '\n'
    suffix = f'.bak.{time.time_ns()}'
    for path in (nl, xml):
        shutil.copy2(path, str(path) + suffix)
    nl.write_text(updated)
    xml.write_text(xml_text)
    print(f'Configurados {nl.name} e {xml.name}; backups com sufixo {suffix}')


if __name__ == '__main__':
    try:
        configure(sys.argv[1])
    except (OSError, ValueError, KeyError, ET.ParseError) as error:
        sys.exit(f'ERRO: {error}')

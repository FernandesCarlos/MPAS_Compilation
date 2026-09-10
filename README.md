# MPAS — Ambiente de Compilação e Baseline Reproduzível

Este projeto prepara o ambiente necessário para **compilação, preparação de dados e execução do MPAS-Atmosphere**. Ele mantém o caminho didático de compilação manual e acrescenta uma baseline automatizada e reproduzível com ERA5.

## Dois modos de uso

### 1. Estudo e compilação manual

O usuário pode estudar e compilar separadamente zlib, HDF5, NetCDF, PnetCDF, PIO, METIS, WPS e MPAS.

### 2. Caso reproduzível end-to-end

A baseline oficial executa:

```text
ERA5 → WPS/ungrib → static.nc → init.nc → MPAS-Atmosphere → history/diagnostics → validação
```

Configuração do caso:

| Parâmetro | Valor |
|---|---|
| MPAS | v8.4.1 |
| WPS | v4.5 |
| Mesh | x1.10242 (~240 km) |
| ERA5 | 2014-09-10 00 UTC |
| Duração | 1 hora |
| `dt` | 1200 s |
| MPI | 4 ranks, MPICH |

## Estrutura

```text
.
├── Dockerfile
├── README.md
├── cases/
│   └── first-global-240km/
│       ├── era5/
│       ├── wps/
│       ├── static/
│       ├── init/
│       └── atmosphere/
├── scripts/
│   ├── data/
│   ├── lib/
│   ├── prepare/
│   ├── run/
│   └── validate/
├── tests/
│   └── smoke/
├── dados-era5/
└── docs/
```

Arquivos científicos grandes ficam em `data/` e `work/` e não são versionados.

## Construção do Docker

```bash
docker build -t mpas .
```

Crie diretórios persistentes:

```bash
mkdir -p data work
```

Inicie o container:

```bash
docker run --rm -it \
  -v "$HOME/.cdsapirc:/root/.cdsapirc:ro" \
  -v "$PWD/data:/workspace/data" \
  -v "$PWD/work:/workspace/work" \
  mpas bash
```

Dentro do container:

```bash
cd /workspace
```

## Smoke tests

Antes da execução científica completa:

```bash
bash tests/smoke/run_all.sh
```

Os smoke tests não precisam baixar a ERA5 e exercitam configuração, dry-runs e tratamento de erro.

## Execução automática completa

```bash
bash scripts/run/full_pipeline.sh
```

O fluxo é:

```text
preflight
→ download ERA5
→ mesh x1.10242
→ WPS_GEOG
→ compilação do WPS/MPAS
→ ungrib
→ particionamento da malha
→ static
→ init
→ atmosphere por 1 hora
→ validação final
```

O relatório final esperado é:

```text
WPS                PASS
STATIC             PASS
INIT               PASS
ATMOSPHERE         PASS
NETCDF_SANITY      PASS
```

Esse PASS indica **integração e sanity básico**, e não forecast skill meteorológico.

## Execução por etapas

```bash
python3 scripts/data/download_era5.py
bash scripts/data/fetch_mesh.sh
bash scripts/data/fetch_geog.sh
bash scripts/prepare/build_tools.sh
bash scripts/prepare/prepare_wps.sh
bash scripts/prepare/partition_mesh.sh
bash scripts/prepare/generate_static.sh
bash scripts/prepare/generate_init.sh
bash scripts/run/run_atmosphere.sh
bash scripts/validate/final_case.sh
```

Para visualizar ações sem executar etapas pesadas, vários scripts aceitam `--dry-run`.

## Reutilização de artefatos

Para não baixar novamente entradas existentes:

```bash
SKIP_DOWNLOAD=1 bash scripts/run/full_pipeline.sh
```

Para usar executáveis já compilados:

```bash
SKIP_BUILD=1 bash scripts/run/full_pipeline.sh
```

Para refazer etapas que suportam sobrescrita:

```bash
FORCE=1 bash scripts/run/full_pipeline.sh
```

## Componentes da stack

- **I/O científico:** zlib, HDF5 paralelo, NetCDF-C, NetCDF-Fortran, PnetCDF e PIO;
- **MPI:** MPICH;
- **Particionamento:** GKlib e METIS;
- **Pré-processamento:** WPS e `ungrib`;
- **GRIB2:** bibliotecas privadas construídas pelo WPS com `--build-grib2-libs`;
- **Modelo:** MPAS-Atmosphere;
- **Dados meteorológicos:** ERA5 via CDS API.

## Compilação manual do MPAS

```bash
cd /mpas/MPAS-Model
make -j$(nproc) gnu CORE=init_atmosphere USE_PIO2=true
make -j$(nproc) gnu CORE=atmosphere USE_PIO2=true
```

A automação equivalente é:

```bash
cd /workspace
bash scripts/prepare/build_tools.sh
```

## Documentação

- [`docs/dependencias/`](docs/dependencias/) — bibliotecas da stack;
- [`docs/particionamento/`](docs/particionamento/) — GKlib e METIS;
- [`docs/wps/`](docs/wps/) — WPS, `ungrib` e suporte GRIB2;
- [`docs/mpas/`](docs/mpas/) — compilação do MPAS;
- [`docs/cases/first-global-240km.md`](docs/cases/first-global-240km.md) — baseline oficial;
- [`docs/reproducibility/end-to-end.md`](docs/reproducibility/end-to-end.md) — reprodução completa;
- [`docs/testing/validation-matrix.md`](docs/testing/validation-matrix.md) — critérios PASS/FAIL.

## Versões principais

| Componente | Versão |
|---|---|
| Ubuntu | 24.04 |
| MPAS | v8.4.1 |
| WPS | v4.5 |
| zlib | 1.3.2 |
| HDF5 | 1.14.6 |
| NetCDF-C | 4.9.3 |
| NetCDF-Fortran | 4.6.2 |
| PnetCDF | 1.12.3 |
| PIO | 2.6.8 |
| METIS | 5.2.1 |

## Dados e credenciais

A credencial CDS deve permanecer fora do Git. Por padrão, o downloader procura:

```text
~/.cdsapirc
```

Também não devem ser versionados GRIBs, WPS intermediates, meshes, `static.nc`, `init.nc`, history, diagnostics ou logs de execução.

## Limite científico da baseline

O experimento de uma hora em uma mesh global grossa foi definido para provar que a cadeia computacional funciona. Ele não mede spin-up, desempenho em integrações longas, escalabilidade ou qualidade da previsão meteorológica.

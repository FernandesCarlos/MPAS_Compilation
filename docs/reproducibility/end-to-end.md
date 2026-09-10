# Reprodução end-to-end: ERA5 → MPAS-Atmosphere

Este guia executa a baseline global `x1.10242` do início ao fim.

## 1. Pré-requisitos no host

São necessários:

- Git;
- Docker Engine;
- acesso à Internet durante construção e aquisição de dados;
- credencial válida do Copernicus Climate Data Store;
- espaço em disco para ERA5, WPS_GEOG, malha, builds e saídas.

A credencial deve estar no host em:

```text
~/.cdsapirc
```

Não copie essa credencial para o Dockerfile nem para o repositório.

## 2. Construção da imagem

Na raiz do repositório:

```bash
docker build -t mpas .
```

O Dockerfile instala a stack científica, MPICH, NetCDF/PnetCDF/PIO e os fontes do WPS e MPAS. Os executáveis WPS/MPAS continuam sendo construídos por scripts separados para que o processo de compilação permaneça visível e didático.

## 3. Diretórios persistentes

Crie os diretórios de dados e trabalho:

```bash
mkdir -p data work
```

Inicie o container montando a credencial e os diretórios:

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

## 4. Smoke tests do repositório

Antes de baixar dados grandes, execute:

```bash
bash tests/smoke/run_all.sh
```

Esses testes verificam configuração, CLIs, dry-runs e tratamento de erro sem executar a previsão completa.

## 5. Preflight

Verifique a toolchain e os fontes:

```bash
bash scripts/validate/preflight.sh
```

Para validar apenas a configuração versionada do caso:

```bash
bash scripts/validate/preflight.sh --config-only
```

## 6. Execução automática completa

O caminho recomendado é:

```bash
bash scripts/run/full_pipeline.sh
```

O script executa, nesta ordem:

```text
preflight → ERA5 → mesh → WPS_GEOG → build → WPS/ungrib →
particionamento → static → init → atmosphere → validação
```

Ao final, o relatório deve conter:

```text
WPS                PASS
STATIC             PASS
INIT               PASS
ATMOSPHERE         PASS
NETCDF_SANITY      PASS
```

## 7. Execução por etapas

Também é possível executar cada etapa separadamente.

### ERA5

```bash
python3 scripts/data/download_era5.py
```

Para visualizar a request sem acessar o CDS:

```bash
python3 scripts/data/download_era5.py --dry-run
```

### Malha

```bash
bash scripts/data/fetch_mesh.sh
```

### Dados geográficos

```bash
bash scripts/data/fetch_geog.sh
```

O conjunto geográfico é grande; downloads já verificados são reutilizados por cache.

### Compilação das ferramentas

```bash
bash scripts/prepare/build_tools.sh
```

Esse script constrói, se ainda não existirem:

```text
WPS/ungrib.exe
MPAS/init_atmosphere_model
MPAS/atmosphere_model
```

Para visualizar os comandos:

```bash
bash scripts/prepare/build_tools.sh --dry-run
```

### WPS/ungrib

```bash
bash scripts/prepare/prepare_wps.sh
```

### Particionamento da malha

```bash
bash scripts/prepare/partition_mesh.sh
```

### Static

```bash
bash scripts/prepare/generate_static.sh
```

### Init

```bash
bash scripts/prepare/generate_init.sh
```

### Atmosphere

```bash
bash scripts/run/run_atmosphere.sh
```

### Validação final

```bash
bash scripts/validate/final_case.sh
```

## 8. Retomar uma execução

Os scripts são projetados para reutilizar artefatos válidos existentes. Assim, após uma falha, corrija o problema e execute novamente o estágio ou o pipeline completo.

Para não refazer downloads:

```bash
SKIP_DOWNLOAD=1 bash scripts/run/full_pipeline.sh
```

Para utilizar executáveis já compilados:

```bash
SKIP_BUILD=1 bash scripts/run/full_pipeline.sh
```

Para reconstruir artefatos gerados pelas etapas que aceitam sobrescrita:

```bash
FORCE=1 bash scripts/run/full_pipeline.sh
```

As variáveis podem ser combinadas:

```bash
SKIP_DOWNLOAD=1 SKIP_BUILD=1 bash scripts/run/full_pipeline.sh
```

## 9. Diretórios gerados

Por padrão:

```text
data/first-global-240km/
├── era5/
├── mesh/
└── WPS_GEOG/

work/first-global-240km/
├── logs/
├── wps/
├── static/
├── init/
└── atmosphere/
```

`data/` contém entradas externas reutilizáveis. `work/` contém artefatos de processamento e resultados da baseline.

## 10. Customização de caminhos

Os principais caminhos podem ser sobrescritos por variáveis de ambiente:

```bash
DATA_ROOT=/dados/meu-caso \
WORK_ROOT=/scratch/meu-caso \
WPS_ROOT=/build/WPS \
MPAS_ROOT=/mpas/MPAS-Model \
MPI_RANKS=4 \
bash scripts/run/full_pipeline.sh
```

A baseline oficial, entretanto, pressupõe quatro ranks. Alterar esse valor transforma a execução em outro experimento e exige novo particionamento da malha.

## 11. Falhas comuns

**Credencial CDS ausente:** confirme que `~/.cdsapirc` foi montado no container.

**`ungrib.exe` ausente:** execute `bash scripts/prepare/build_tools.sh`.

**Malha ou WPS_GEOG ausente:** execute os scripts em `scripts/data/`.

**`gpmetis` ausente:** confirme a instalação do METIS e o `PATH` de `/dependencias/metis/bin`.

**Biblioteca não encontrada:** execute `ldd` no executável correspondente e confira `NETCDF`, `PNETCDF`, `PIO` e `LD_LIBRARY_PATH`.

**Saída NetCDF com FAIL:** preserve os logs em `work/first-global-240km/logs/` e verifique a primeira etapa que falhou antes de repetir a previsão.

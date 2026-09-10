# Compilação do MPAS

Este projeto mantém dois caminhos complementares: **compilação manual**, para estudo da stack, e **compilação automatizada**, utilizada pela baseline reproduzível.

## 1. Dependências

| Dependência | Diretório |
|---|---|
| NetCDF-C / Fortran | `/dependencias/netcdf` |
| PnetCDF | `/dependencias/pnetcdf` |
| PIO | `/dependencias/pio` |
| METIS | `/dependencias/metis` |
| HDF5 | `/dependencias/hdf5` |
| zlib | `/dependencias/zlib` |

O ambiente utiliza **MPICH**, portanto os wrappers principais são:

```bash
mpicc --version
mpicxx --version
mpif90 --version
mpiexec --version
```

## 2. Variáveis de ambiente

```bash
export NETCDF=/dependencias/netcdf
export PNETCDF=/dependencias/pnetcdf
export PIO=/dependencias/pio
export PATH="/dependencias/netcdf/bin:/dependencias/pnetcdf/bin:/dependencias/pio/bin:/dependencias/metis/bin:${PATH}"
export LD_LIBRARY_PATH="/dependencias/zlib/lib:/dependencias/hdf5/lib:/dependencias/netcdf/lib:/dependencias/pnetcdf/lib:/dependencias/pio/lib:/dependencias/metis/lib:${LD_LIBRARY_PATH:-}"
```

Verifique:

```bash
nc-config --version
nf-config --version
gpmetis -help | head
```

## 3. Código-fonte

A baseline utiliza **MPAS v8.4.1**. No container, o código está em:

```text
/mpas/MPAS-Model
```

Para obter manualmente:

```bash
git clone --depth 1 --branch v8.4.1 \
  https://github.com/MPAS-Dev/MPAS-Model.git
```

## 4. `init_atmosphere`

A baseline necessita do executável responsável pelas etapas de static e inicialização meteorológica:

```bash
cd /mpas/MPAS-Model
make -j$(nproc) gnu CORE=init_atmosphere USE_PIO2=true
```

O resultado esperado é:

```text
init_atmosphere_model
```

## 5. `atmosphere`

Para o modelo atmosférico:

```bash
cd /mpas/MPAS-Model
make -j$(nproc) gnu CORE=atmosphere USE_PIO2=true
```

O resultado esperado é:

```text
atmosphere_model
```

Durante a compilação do core `atmosphere`, o próprio source do MPAS executa o mecanismo de obtenção das tabelas de física WRF quando elas ainda não estão presentes. Para MPAS 8.4.1, o script upstream verifica compatibilidade com as tabelas da linha MPAS-Data 8.2.

## 6. Verificação de linkagem

Após a compilação:

```bash
ldd init_atmosphere_model
ldd atmosphere_model
```

Nenhuma linha deve conter:

```text
not found
```

Também é útil verificar a stack:

```bash
echo "$NETCDF"
echo "$PNETCDF"
echo "$PIO"
```

## 7. Compilação automatizada

Para preparar todos os executáveis necessários à baseline:

```bash
cd /workspace
bash scripts/prepare/build_tools.sh
```

O script:

- compila `WPS/ungrib.exe` se necessário;
- compila `init_atmosphere_model` se necessário;
- compila `atmosphere_model` se necessário;
- reutiliza executáveis já existentes;
- executa `ldd` e rejeita bibliotecas não resolvidas;
- preserva logs em `work/first-global-240km/logs/`.

Para mostrar os comandos sem executá-los:

```bash
bash scripts/prepare/build_tools.sh --dry-run
```

O fluxo apresentado é:

```text
WPS configure/compile → init_atmosphere build → atmosphere build → linkagem
```

## 8. Diferença entre build e execução

Compilar o MPAS apenas produz os executáveis. A reprodução científica ainda necessita de dados e configurações:

```text
compilação
   → ERA5
   → WPS intermediate
   → mesh + WPS_GEOG
   → static.nc
   → init.nc
   → atmosphere_model
   → history / diagnostics
```

O pipeline completo pode ser executado com:

```bash
bash scripts/run/full_pipeline.sh
```

## 9. Execução oficial da baseline

Depois da geração de `x1.10242.init.nc`, o modelo é executado com:

```bash
mpiexec -n 4 /mpas/MPAS-Model/atmosphere_model
```

A configuração fixa é:

```text
início: 2014-09-10 00 UTC
duração: 01:00:00
dt: 1200 s
MPI ranks: 4
mesh: x1.10242
```

A geração dos dados e a execução são descritas em [`../reproducibility/end-to-end.md`](../reproducibility/end-to-end.md).

## 10. Problemas comuns

**NetCDF não encontrado:** confira `NETCDF`, `PATH` e `LD_LIBRARY_PATH`.

**PIO/PnetCDF não encontrado:** confirme `/dependencias/pio` e `/dependencias/pnetcdf`.

**Erro no core atmosphere ao buscar tabelas de física:** verifique conectividade durante o primeiro build e o diretório `src/core_atmosphere/physics/physics_wrf/files`.

**Executável existe, mas não inicia:** execute `ldd` e procure por `not found`.

**Compilação consome memória demais:** reduza o paralelismo, por exemplo:

```bash
BUILD_JOBS=2 bash scripts/prepare/build_tools.sh
```

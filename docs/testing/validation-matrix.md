# Matriz de validação da baseline

A baseline separa verificações de ambiente, integração e sanity científico. Um teste de integração bem-sucedido não deve ser interpretado como validação da qualidade meteorológica da previsão.

| Etapa | Evidência | Critério de PASS | Script |
|---|---|---|---|
| Configuração | `case.env` | data, duração, `dt` e 4 ranks corretos | `tests/smoke/test_case_config.sh` |
| Requests ERA5 | JSONs versionados | 2014-09-10 00 UTC, domínio global e variáveis esperadas | `tests/smoke/test_era5_requests.py` |
| Toolchain | comandos e fontes | MPI, compiladores, NetCDF, METIS, WPS e MPAS localizados | `scripts/validate/preflight.sh` |
| Build WPS | `ungrib.exe` | executável gerado e linkagem sem `not found` | `scripts/prepare/build_tools.sh` |
| Build MPAS init | `init_atmosphere_model` | executável gerado e linkagem válida | `scripts/prepare/build_tools.sh` |
| Build MPAS atmosphere | `atmosphere_model` | executável gerado e linkagem válida | `scripts/prepare/build_tools.sh` |
| ERA5 pressure | GRIB | arquivo não vazio obtido pelo CDS | `scripts/data/download_era5.py` |
| ERA5 surface | GRIB | arquivo não vazio obtido pelo CDS | `scripts/data/download_era5.py` |
| WPS | `ERA5:2014-09-10_00` | intermediário combinado não vazio | `scripts/prepare/prepare_wps.sh` |
| Mesh | `x1.10242.grid.nc` + graph | archive com SHA-256 esperado e grafo com 10242 células | `scripts/data/fetch_mesh.sh` |
| Particionamento | `.part.4` | `gpmetis` produz arquivo não vazio | `scripts/prepare/partition_mesh.sh` |
| Static | `x1.10242.static.nc` | NetCDF gerado e legível | `scripts/prepare/generate_static.sh` + `validate_outputs.py` |
| Init | `x1.10242.init.nc` | NetCDF gerado, legível e com estrutura temporal | `scripts/prepare/generate_init.sh` + `validate_outputs.py` |
| Atmosphere | `history.*.nc` | ao menos um history produzido | `scripts/run/run_atmosphere.sh` |
| Diagnostics | `diag.*.nc` | ao menos um diagnostics produzido | `scripts/run/run_atmosphere.sh` |
| Sanity numérico | variáveis numéricas | nenhum NaN/Inf não mascarado nos arquivos verificados | `scripts/validate/validate_outputs.py` |
| Variável de superfície | `t2m` | presente em history | `scripts/validate/validate_outputs.py --require-var t2m` |
| Relatório final | cinco estados | `WPS`, `STATIC`, `INIT`, `ATMOSPHERE` e `NETCDF_SANITY` = PASS | `scripts/validate/final_case.sh` |

## Níveis de teste

### Smoke tests

Os smoke tests verificam interfaces do repositório sem exigir download da ERA5 ou uma execução científica completa:

```bash
bash tests/smoke/run_all.sh
```

Eles exercitam principalmente configuração, tratamento de erros e modos `--dry-run`.

### Integração científica

A integração completa exige dados externos, WPS_GEOG, malha e tempo de compilação/execução:

```bash
bash scripts/run/full_pipeline.sh
```

O resultado esperado é o relatório final com todos os estados em PASS.

### Sanity científico

O sanity implementado é deliberadamente básico. Ele verifica integridade estrutural e valores finitos e confirma que campos importantes, como `t2m`, foram materializados. Não compara a previsão com observações futuras e não calcula métricas de skill.

## Condições que devem gerar FAIL

A validação deve falhar quando ocorrer qualquer uma das seguintes condições:

- arquivo obrigatório ausente ou vazio;
- executável obrigatório ausente;
- biblioteca dinâmica não resolvida;
- falha do `ungrib`, `init_atmosphere_model` ou `atmosphere_model`;
- falta de history ou diagnostics;
- NetCDF que não pode ser aberto;
- dimensão obrigatória vazia;
- variável obrigatória ausente;
- NaN ou infinito em variável numérica não mascarada.

## Fora do escopo desta matriz

Não são critérios da baseline:

- RMSE, bias, correlação ou outras métricas contra observação;
- spin-up de modelo;
- conservação de longo prazo;
- escalabilidade MPI;
- benchmark de performance;
- comparação MPICH versus OpenMPI;
- aceleração GPU.

# Caso oficial: MPAS global x1.10242 (~240 km)

Este caso é a baseline reproduzível do projeto. Ele foi criado para verificar se a cadeia completa **ERA5 → WPS → init_atmosphere → MPAS-Atmosphere** funciona de forma integrada no ambiente construído pelo repositório.

## Configuração fixa

| Parâmetro | Valor |
|---|---|
| MPAS-Atmosphere | v8.4.1 |
| Malha | x1.10242 |
| Resolução aproximada | 240 km |
| Domínio | Global |
| Data inicial | 2014-09-10 00 UTC |
| Duração | 1 hora |
| `config_dt` | 1200 s |
| MPI | 4 ranks |
| Implementação MPI do projeto | MPICH |
| Physics suite | `mesoscale_reference` |

A configuração é deliberadamente pequena. O objetivo é tornar possível testar o pipeline sem transformar a baseline em uma simulação operacional de grande porte.

## Fluxo científico

O caso executa o seguinte fluxo:

```text
ERA5 pressure levels + ERA5 single levels
        → WPS/ungrib
        → ERA5:2014-09-10_00
        → init_atmosphere (static)
        → x1.10242.static.nc
        → init_atmosphere (meteorological initialization)
        → x1.10242.init.nc
        → atmosphere_model
        → history + diagnostics
        → validação estrutural e sanity
```

## ERA5

As requests ficam versionadas em:

```text
cases/first-global-240km/era5/pressure-levels.json
cases/first-global-240km/era5/single-levels.json
```

O download gera dois arquivos GRIB:

```text
data/first-global-240km/era5/era5-pressure-levels.grib
data/first-global-240km/era5/era5-single-levels.grib
```

A credencial do Climate Data Store deve permanecer somente no host, normalmente em `~/.cdsapirc`.

## WPS

O `ungrib` é executado separadamente para pressão e superfície:

```text
era5-pressure-levels.grib → ERA5_PRES:2014-09-10_00
era5-single-levels.grib   → ERA5_SFC:2014-09-10_00
```

Os dois intermediários são concatenados em:

```text
ERA5:2014-09-10_00
```

Esse prefixo é o que o `init_atmosphere` utiliza por meio de `config_met_prefix = 'ERA5'`.

## Malha e particionamento

A malha oficial é obtida do arquivo `x1.10242.tar.gz`, contendo:

```text
x1.10242.grid.nc
x1.10242.graph.info
```

Para a execução com quatro ranks, o grafo é particionado com METIS:

```bash
gpmetis -minconn -contig -niter=200 x1.10242.graph.info 4
```

O arquivo resultante é:

```text
x1.10242.graph.info.part.4
```

## Static

A primeira execução de `init_atmosphere_model` interpola os dados geográficos para a malha MPAS e produz:

```text
x1.10242.static.nc
```

Essa etapa utiliza a malha `x1.10242` e os datasets WPS_GEOG necessários ao MPAS.

## Condição inicial

A segunda execução de `init_atmosphere_model` combina:

```text
x1.10242.static.nc + ERA5:2014-09-10_00 + partição da malha
```

para produzir:

```text
x1.10242.init.nc
```

## Integração atmosférica

A execução oficial é:

```bash
mpiexec -n 4 /mpas/MPAS-Model/atmosphere_model
```

com:

```text
config_start_time = 2014-09-10_00:00:00
config_run_duration = 01:00:00
config_dt = 1200.0
```

São esperados arquivos `history.*.nc` e `diag.*.nc`.

## O que significa PASS

Um PASS da baseline significa que:

- os dados necessários foram preparados;
- o WPS produziu um intermediário utilizável;
- `static.nc` foi gerado;
- `init.nc` foi gerado;
- o MPAS executou o intervalo configurado;
- arquivos history e diagnostics foram produzidos;
- os NetCDFs podem ser abertos e não apresentam NaN/Inf nas variáveis numéricas verificadas.

## O que o caso não valida

A baseline **não deve ser interpretada como validação da qualidade da previsão meteorológica**. Uma simulação de apenas uma hora e com malha grossa é adequada para teste de integração e sanity, mas é insuficiente para avaliar:

- forecast skill;
- spin-up;
- desempenho multiday;
- escalabilidade de produção;
- conservação completa de água e energia;
- adequação científica a um estudo específico.

Para executar o caso do início ao fim, consulte [`../reproducibility/end-to-end.md`](../reproducibility/end-to-end.md).

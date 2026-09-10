# Preparação do ERA5 com `ungrib`

## 1. Função do `ungrib`

O `ungrib` lê dados meteorológicos em GRIB e produz arquivos no formato intermediário do WPS. Esses arquivos são utilizados posteriormente pelo `init_atmosphere` para interpolar as condições meteorológicas para a malha MPAS.

Na baseline deste repositório, a entrada é ERA5 de **2014-09-10 00 UTC**.

## 2. Por que existem duas execuções

Os dados são baixados em dois conjuntos:

```text
era5-pressure-levels.grib
era5-single-levels.grib
```

Cada conjunto é processado separadamente:

```text
era5-pressure-levels.grib → ERA5_PRES:2014-09-10_00
era5-single-levels.grib   → ERA5_SFC:2014-09-10_00
```

Depois, os intermediários são concatenados:

```text
ERA5_PRES:2014-09-10_00 + ERA5_SFC:2014-09-10_00
                           ↓
                  ERA5:2014-09-10_00
```

Esse último nome é compatível com:

```fortran
config_met_prefix = 'ERA5'
```

na configuração do `init_atmosphere`.

## 3. Namelists

Os arquivos versionados ficam em:

```text
cases/first-global-240km/wps/pressure/namelist.wps
cases/first-global-240km/wps/single/namelist.wps
```

A diferença principal é o prefixo de saída:

```fortran
prefix = 'ERA5_PRES'
```

ou:

```fortran
prefix = 'ERA5_SFC'
```

## 4. Vtable

O ERA5 é interpretado usando a tabela ECMWF fornecida pelo WPS:

```text
/build/WPS/ungrib/Variable_Tables/Vtable.ECMWF
```

No diretório de execução é criado o link:

```bash
ln -s /build/WPS/ungrib/Variable_Tables/Vtable.ECMWF Vtable
```

## 5. Ligação dos GRIBs

O WPS fornece o script `link_grib.csh` para criar nomes como:

```text
GRIBFILE.AAA
GRIBFILE.AAB
...
```

Para um arquivo:

```bash
/build/WPS/link_grib.csh /caminho/era5-pressure-levels.grib
```

Depois:

```bash
/build/WPS/ungrib.exe
```

## 6. Automação do projeto

A preparação completa é executada por:

```bash
bash scripts/prepare/prepare_wps.sh
```

O script:

1. verifica se os dois GRIBs existem;
2. prepara um diretório de trabalho para pressure levels;
3. liga a `Vtable.ECMWF`;
4. executa `ungrib.exe`;
5. repete o processo para single levels;
6. exige que as duas saídas tenham sido criadas;
7. combina os dois intermediários em `ERA5:2014-09-10_00`.

Para visualizar o plano:

```bash
bash scripts/prepare/prepare_wps.sh --dry-run
```

Para refazer os intermediários:

```bash
bash scripts/prepare/prepare_wps.sh --force
```

## 7. Arquivos esperados

Após sucesso:

```text
work/first-global-240km/wps/
├── ERA5_PRES:2014-09-10_00
├── ERA5_SFC:2014-09-10_00
└── ERA5:2014-09-10_00
```

Se `ungrib.exe` ainda não existir, execute:

```bash
bash scripts/prepare/build_tools.sh
```

## 8. Próxima etapa

Depois do WPS, a cadeia segue para:

```text
WPS intermediate → x1.10242.static.nc + malha particionada → init_atmosphere → x1.10242.init.nc
```

A execução completa está descrita em [`../reproducibility/end-to-end.md`](../reproducibility/end-to-end.md).

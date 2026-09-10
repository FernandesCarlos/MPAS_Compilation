# WPS e `ungrib` no pipeline MPAS + ERA5

O **WPS (WRF Preprocessing System)** é utilizado neste projeto principalmente pelo programa `ungrib`, que lê arquivos GRIB do ERA5 e os converte para o formato intermediário consumido pelo `init_atmosphere` do MPAS.

O fluxo adotado é:

```text
ERA5 pressure levels → ungrib → ERA5_PRES:2014-09-10_00
ERA5 single levels   → ungrib → ERA5_SFC:2014-09-10_00
                                  ↓
                           concatenação
                                  ↓
                         ERA5:2014-09-10_00
                                  ↓
                         MPAS init_atmosphere
```

## Versão

O ambiente utiliza **WPS v4.5**. O código-fonte fica em:

```text
/build/WPS
```

## Caminho manual

A instalação e compilação manual estão descritas em [`INSTALACAO.md`](INSTALACAO.md).

O processamento ERA5 com `ungrib` está descrito em [`ungrib.md`](ungrib.md).

A relação do JasPer com dados GRIB2 está explicada em [`jasper.md`](jasper.md).

## Caminho automatizado

A automação do projeto compila o `ungrib` quando necessário:

```bash
bash scripts/prepare/build_tools.sh
```

O comando de configuração utilizado é baseado no modo oficial do WPS que não exige uma compilação do WRF:

```bash
./configure --nowrf --build-grib2-libs
./compile ungrib
```

Em seguida, o ERA5 é preparado com:

```bash
bash scripts/prepare/prepare_wps.sh
```

Para apenas visualizar o que será executado:

```bash
bash scripts/prepare/prepare_wps.sh --dry-run
```

## Configurações versionadas

A baseline possui dois `namelist.wps` separados:

```text
cases/first-global-240km/wps/pressure/namelist.wps
cases/first-global-240km/wps/single/namelist.wps
```

A separação evita misturar, no mesmo `ungrib`, os conjuntos de níveis de pressão e superfície antes de verificar que cada conversão produziu sua saída.

## Vtable

Os dois conjuntos ERA5 utilizam:

```text
/build/WPS/ungrib/Variable_Tables/Vtable.ECMWF
```

Durante a preparação, o script cria o link `Vtable` no diretório de trabalho.

## Onde ficam as saídas

Por padrão:

```text
work/first-global-240km/wps/
├── ERA5_PRES:2014-09-10_00
├── ERA5_SFC:2014-09-10_00
└── ERA5:2014-09-10_00
```

O último arquivo é utilizado na geração de `x1.10242.init.nc`.

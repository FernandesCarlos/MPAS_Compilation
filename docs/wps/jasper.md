# JasPer e suporte a GRIB2 no WPS

O **JasPer** é uma biblioteca utilizada para JPEG-2000 e aparece no ecossistema do WPS porque arquivos GRIB2 podem utilizar esse tipo de compressão.

Neste projeto, o caminho automatizado **não instala uma cópia independente do JasPer em `/dependencias/jasper`**. Em vez disso, o script de build utiliza a opção oficial do WPS:

```bash
./configure --nowrf --build-grib2-libs
```

Com `--build-grib2-libs`, o WPS constrói suas bibliotecas privadas para GRIB2, incluindo zlib, libpng e JasPer, no próprio ambiente de compilação do WPS.

## Fluxo automatizado

```text
WPS source
   → configure --nowrf --build-grib2-libs
   → bibliotecas GRIB2 privadas
   → compile ungrib
   → ungrib.exe
   → ERA5 GRIB
   → WPS intermediate
```

O comando do projeto é:

```bash
bash scripts/prepare/build_tools.sh
```

Para inspecionar os comandos sem executar a compilação:

```bash
bash scripts/prepare/build_tools.sh --dry-run
```

## Por que usar as bibliotecas do próprio WPS

Essa estratégia reduz a necessidade de manter manualmente outra cadeia de headers e bibliotecas apenas para o `ungrib`. Também mantém a configuração do GRIB2 associada à versão do WPS que está sendo utilizada.

O restante da stack científica do MPAS continua instalado em `/dependencias`, incluindo HDF5, NetCDF, PnetCDF, PIO e METIS.

## Instalação manual alternativa

Se for necessário estudar ou testar uma instalação externa do JasPer, ele pode ser compilado separadamente e exposto ao WPS por variáveis como `JASPERINC` e `JASPERLIB`. Esse é um caminho alternativo e não é necessário para a baseline oficial.

Em uma instalação externa, a organização típica seria:

```text
/dependencias/jasper/
├── include/
└── lib/
```

seguida de:

```bash
export JASPERINC=/dependencias/jasper/include
export JASPERLIB=/dependencias/jasper/lib
```

Ao optar por esse caminho, é responsabilidade do usuário garantir compatibilidade entre a versão do JasPer, os compiladores e o WPS.

## Relação com o MPAS

O JasPer não é uma dependência direta do núcleo atmosférico do MPAS. Sua função nesta cadeia está no pré-processamento:

```text
ERA5 GRIB → WPS/ungrib → formato intermediário → init_atmosphere → MPAS
```

Para o procedimento usado pelo projeto, consulte [`INSTALACAO.md`](INSTALACAO.md) e [`ungrib.md`](ungrib.md).

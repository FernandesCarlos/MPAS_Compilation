# Instalação e compilação do WPS

## 1. Objetivo

Neste projeto, o WPS é usado principalmente para disponibilizar o **`ungrib`**, responsável por converter dados GRIB do ERA5 para o formato intermediário lido pelo `init_atmosphere` do MPAS.

Não é necessário compilar o WRF para esse uso. O WPS suporta o modo `--nowrf`, que permite construir ferramentas que não dependem da biblioteca de I/O do WRF, incluindo o `ungrib`.

## 2. Dependências

O ambiente precisa de:

- GCC e GFortran;
- `csh`;
- GNU Make;
- NetCDF;
- ferramentas básicas de compilação.

No container deste projeto, NetCDF está em:

```text
/dependencias/netcdf
```

Defina:

```bash
export NETCDF=/dependencias/netcdf
```

## 3. Código-fonte

A versão utilizada é **WPS v4.5**:

```bash
git clone --depth 1 --branch v4.5 \
    https://github.com/wrf-model/WPS.git \
    /build/WPS
```

Entre no diretório:

```bash
cd /build/WPS
```

## 4. Configuração para `ungrib`

Para a baseline, a configuração recomendada é:

```bash
./configure --nowrf --build-grib2-libs
```

O parâmetro `--nowrf` desabilita a exigência de um WRF previamente compilado.

O parâmetro `--build-grib2-libs` faz o WPS construir as bibliotecas GRIB2 privadas fornecidas pelo próprio source, incluindo zlib, libpng e JasPer utilizadas no processamento GRIB2.

Durante o menu de configuração, selecione a opção **Linux x86_64, gfortran (serial)**. O `ungrib` é executado serialmente; o paralelismo MPI é utilizado posteriormente pelo MPAS.

## 5. Compilação

Compile somente o `ungrib`:

```bash
./compile ungrib
```

Ao final, verifique:

```bash
ls -l /build/WPS/ungrib.exe
ldd /build/WPS/ungrib.exe
```

Não deve aparecer nenhuma dependência marcada como `not found`.

## 6. Automação

O repositório automatiza esse processo com:

```bash
bash scripts/prepare/build_tools.sh
```

O script detecta se `ungrib.exe` já existe. Se existir, a compilação é reutilizada; caso contrário, ele seleciona a configuração GNU serial e executa os comandos acima.

Para visualizar os comandos sem compilar:

```bash
bash scripts/prepare/build_tools.sh --dry-run
```

## 7. Processamento do ERA5

Depois da compilação:

```bash
bash scripts/prepare/prepare_wps.sh
```

Consulte [`ungrib.md`](ungrib.md) para o fluxo detalhado dos dois conjuntos ERA5.

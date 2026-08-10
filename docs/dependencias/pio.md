# Instalação do PIO (ParallelIO)

## 1. Instalação sem Docker

O **PIO (ParallelIO)** é uma biblioteca desenvolvida pelo NCAR para fornecer uma camada de abstração para **entrada e saída paralela (Parallel I/O)**.

No ambiente do MPAS, o PIO é utilizado para gerenciar as operações de I/O paralelo e pode utilizar diferentes bibliotecas de armazenamento, incluindo:

* NetCDF-C;
* NetCDF-Fortran;
* PnetCDF.

Neste ambiente, o PIO será instalado em:

```text
/dependencias/pio
```

### 1.1. Dependências

O PIO depende das bibliotecas NetCDF e PnetCDF instaladas anteriormente.

A estrutura esperada é:

```text
/dependencias/netcdf
/dependencias/pnetcdf
```

Também é necessário possuir MPI e CMake:

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc gfortran \
    cmake \
    mpich libmpich-dev
```

Verifique o ambiente MPI:

```bash
mpicc --version
mpif90 --version
```

Verifique o CMake:

```bash
cmake --version
```

---

## 1.2. Download

Defina a versão:

```bash
export PIO_VERSION=2.6.8
```

O código-fonte pode ser obtido diretamente do repositório oficial:

```bash
wget https://github.com/NCAR/ParallelIO/archive/refs/tags/pio$(echo ${PIO_VERSION} | tr . _).tar.gz \
    -O pio-${PIO_VERSION}.tar.gz
```

Extraia:

```bash
tar xzf pio-${PIO_VERSION}.tar.gz
```

Entre no diretório:

```bash
cd ParallelIO-pio$(echo ${PIO_VERSION} | tr . _)
```

---

## 1.3. Configuração

O PIO utiliza **CMake** para configurar sua compilação.

Crie um diretório separado para os arquivos de build:

```bash
mkdir build
cd build
```

Configure:

```bash
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/dependencias/pio \
    -DNetCDF_C_PATH=/dependencias/netcdf \
    -DNetCDF_Fortran_PATH=/dependencias/netcdf \
    -DPnetCDF_PATH=/dependencias/pnetcdf \
    -DPIO_ENABLE_FORTRAN=ON \
    -DPIO_ENABLE_TESTS=OFF \
    -DPIO_ENABLE_EXAMPLES=OFF \
    -DPIO_ENABLE_TIMING=OFF \
    -DCMAKE_C_COMPILER=mpicc \
    -DCMAKE_Fortran_COMPILER=mpif90
```

As principais opções são:

| Opção                     | Função                           |
| ------------------------- | -------------------------------- |
| `CMAKE_INSTALL_PREFIX`    | Define o diretório de instalação |
| `NetCDF_C_PATH`           | Localização do NetCDF-C          |
| `NetCDF_Fortran_PATH`     | Localização do NetCDF-Fortran    |
| `PnetCDF_PATH`            | Localização do PnetCDF           |
| `PIO_ENABLE_FORTRAN=ON`   | Habilita suporte Fortran         |
| `PIO_ENABLE_TESTS=OFF`    | Desabilita testes                |
| `PIO_ENABLE_EXAMPLES=OFF` | Desabilita exemplos              |
| `PIO_ENABLE_TIMING=OFF`   | Desabilita mecanismos de timing  |
| `CMAKE_C_COMPILER`        | Define o compilador C            |
| `CMAKE_Fortran_COMPILER`  | Define o compilador Fortran      |

O ponto principal é informar ao CMake onde estão instaladas as dependências:

```text
NetCDF-C
    ↓
/dependencias/netcdf

NetCDF-Fortran
    ↓
/dependencias/netcdf

PnetCDF
    ↓
/dependencias/pnetcdf
```

---

## 1.4. Compilação

Depois da configuração, compile:

```bash
make -j$(nproc)
```

Como os testes foram desabilitados através de:

```bash
-DPIO_ENABLE_TESTS=OFF
```

não é necessário executar `make check` neste ambiente.

---

## 1.5. Instalação

Instale o PIO:

```bash
make install
```

A instalação será realizada em:

```text
/dependencias/pio
```

A estrutura resultante será semelhante a:

```text
/dependencias/pio/
├── bin/
├── include/
├── lib/
└── share/
```

---

## 1.6. Configuração do ambiente

Defina:

```bash
export PIO=/dependencias/pio
```

Adicione os executáveis:

```bash
export PATH="${PIO}/bin:${PATH}"
```

Adicione as bibliotecas:

```bash
export LD_LIBRARY_PATH="${PIO}/lib:${LD_LIBRARY_PATH}"
```

Como o PIO depende do NetCDF e do PnetCDF, é recomendável manter também:

```bash
export NETCDF=/dependencias/netcdf
export PNETCDF=/dependencias/pnetcdf
```

E disponibilizar suas bibliotecas:

```bash
export LD_LIBRARY_PATH="/dependencias/pio/lib:/dependencias/netcdf/lib:/dependencias/pnetcdf/lib:${LD_LIBRARY_PATH}"
```

---

## 1.7. Verificação

Verifique os arquivos instalados:

```bash
ls /dependencias/pio/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/pio/lib
```

Também é possível verificar os arquivos de configuração gerados pelo CMake:

```bash
find /dependencias/pio -type f | grep -E "cmake|PIO"
```

---

# 2. Instalação com Docker

No seu `Dockerfile`, o PIO é compilado utilizando **CMake**.

A versão é definida por:

```dockerfile
ARG PIO_VERSION=2.6.8
```

As dependências utilizadas são:

```text
/dependencias/netcdf
/dependencias/pnetcdf
```

E o PIO é instalado em:

```text
/dependencias/pio
```

---

## 2.1. Compilação no Dockerfile

O bloco utilizado no seu `Dockerfile` é:

```dockerfile
RUN cd /build && \
    wget https://github.com/NCAR/ParallelIO/archive/refs/tags/pio$(echo ${PIO_VERSION} | tr . _).tar.gz \
    -O pio-${PIO_VERSION}.tar.gz && \
    tar xzf pio-${PIO_VERSION}.tar.gz && \
    cd ParallelIO-pio$(echo ${PIO_VERSION} | tr . _) && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/dependencias/pio \
        -DNetCDF_C_PATH=/dependencias/netcdf \
        -DNetCDF_Fortran_PATH=/dependencias/netcdf \
        -DPnetCDF_PATH=/dependencias/pnetcdf \
        -DPIO_ENABLE_FORTRAN=ON \
        -DPIO_ENABLE_TESTS=OFF \
        -DPIO_ENABLE_EXAMPLES=OFF \
        -DPIO_ENABLE_TIMING=OFF \
        -DCMAKE_C_COMPILER=mpicc \
        -DCMAKE_Fortran_COMPILER=mpif90 && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/pio* /build/ParallelIO*
```

O processo é:

```text
Download
   ↓
Extração
   ↓
Criação do diretório build
   ↓
Configuração com CMake
   ↓
Compilação
   ↓
Instalação
   ↓
Remoção dos arquivos temporários
```

---

## 2.2. Dependências utilizadas

O PIO recebe explicitamente os caminhos das bibliotecas previamente instaladas:

```text
NetCDF-C
    ↓
/dependencias/netcdf

NetCDF-Fortran
    ↓
/dependencias/netcdf

PnetCDF
    ↓
/dependencias/pnetcdf
```

Isso é definido no CMake através de:

```bash
-DNetCDF_C_PATH=/dependencias/netcdf
-DNetCDF_Fortran_PATH=/dependencias/netcdf
-DPnetCDF_PATH=/dependencias/pnetcdf
```

Assim, o CMake consegue localizar os headers e bibliotecas necessários.

---

## 2.3. Compiladores

No `Dockerfile`, o PIO é compilado utilizando:

```bash
-DCMAKE_C_COMPILER=mpicc
-DCMAKE_Fortran_COMPILER=mpif90
```

Dessa forma, o PIO é compilado utilizando a mesma implementação MPI das demais dependências.

A configuração pode ser representada por:

```text
CMake
  │
  ├── mpicc
  │     └── código C + MPI
  │
  └── mpif90
        └── código Fortran + MPI
```

---

## 2.4. Opções desabilitadas

O seu `Dockerfile` utiliza:

```bash
-DPIO_ENABLE_TESTS=OFF
-DPIO_ENABLE_EXAMPLES=OFF
-DPIO_ENABLE_TIMING=OFF
```

Essas opções reduzem o conteúdo compilado, mantendo o foco na utilização do PIO como dependência do MPAS.

O suporte Fortran permanece habilitado:

```bash
-DPIO_ENABLE_FORTRAN=ON
```

---

## 2.5. Variáveis de ambiente

Após a instalação, seu `Dockerfile` define:

```dockerfile
ENV PIO=/dependencias/pio
```

O diretório dos executáveis é adicionado ao `PATH`:

```dockerfile
ENV PATH="/dependencias/pio/bin:${PATH}"
```

E as bibliotecas são disponibilizadas através de:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/pio/lib:/dependencias/netcdf/lib:/dependencias/pnetcdf/lib:${LD_LIBRARY_PATH}"
```

---

## 2.6. Construção da imagem

Com o bloco do PIO presente no `Dockerfile`:

```bash
docker build -t mpas-pio .
```

O Docker realizará automaticamente todas as etapas de compilação.

---

## 2.7. Verificação no container

Execute um shell dentro do container:

```bash
docker run --rm -it mpas-pio bash
```

Verifique o diretório de instalação:

```bash
ls /dependencias/pio
```

Verifique os headers:

```bash
ls /dependencias/pio/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/pio/lib
```

---

# 3. Relação com o MPAS

O PIO ocupa uma posição importante na cadeia de I/O do MPAS.

A estrutura das dependências é:

```text
zlib
  ↓
HDF5
  ↓
NetCDF-C
  ↓
NetCDF-Fortran
  ↓
PnetCDF
  ↓
PIO
  ↓
MPAS
```

O PIO atua como uma **camada intermediária de I/O paralelo** entre o MPAS e as bibliotecas responsáveis pelo armazenamento dos dados.

De forma simplificada:

```text
                    MPAS
                      │
                      ▼
                     PIO
                 ┌────┴────┐
                 │         │
                 ▼         ▼
              NetCDF    PnetCDF
                 │         │
                 ▼         ▼
               HDF5      NetCDF
```

Essa arquitetura permite que o MPAS utilize diferentes mecanismos de I/O sem precisar implementar diretamente toda a lógica de comunicação paralela e escrita dos arquivos.

---

# 4. Resumo

| Item               | Configuração            |
| ------------------ | ----------------------- |
| Biblioteca         | PIO / ParallelIO        |
| Versão             | `2.6.8`                 |
| Build system       | CMake                   |
| Compilador C       | `mpicc`                 |
| Compilador Fortran | `mpif90`                |
| Fortran            | Habilitado              |
| Testes             | Desabilitados           |
| Exemplos           | Desabilitados           |
| Timing             | Desabilitado            |
| NetCDF-C           | `/dependencias/netcdf`  |
| NetCDF-Fortran     | `/dependencias/netcdf`  |
| PnetCDF            | `/dependencias/pnetcdf` |
| Instalação         | `/dependencias/pio`     |
| Build              | `make`                  |
| Instalação         | `make install`          |

No ambiente do MPAS, o PIO é compilado **depois do NetCDF-C, NetCDF-Fortran e PnetCDF**, pois precisa localizar essas bibliotecas durante a configuração do CMake.

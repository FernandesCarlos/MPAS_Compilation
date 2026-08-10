# Instalação do PnetCDF

## 1. Instalação sem Docker

O **PnetCDF (Parallel NetCDF)** é uma biblioteca desenvolvida para realizar operações de entrada e saída paralelas utilizando o formato NetCDF clássico. No ambiente do MPAS, ele é utilizado pelo **PIO (Parallel I/O)** como uma das opções de backend para operações de I/O paralelo.

O PnetCDF será instalado em:

```text
/dependencias/pnetcdf
```

### 1.1. Dependências

Em sistemas baseados em Ubuntu, instale as ferramentas necessárias:

```bash
sudo apt-get update
sudo apt-get install -y wget tar build-essential \
    gcc g++ gfortran make mpich libmpich-dev
```

Verifique os compiladores MPI:

```bash
mpicc --version
mpicxx --version
mpif90 --version
```

O PnetCDF será compilado utilizando os wrappers MPI:

```text
mpicc
mpicxx
mpif90
```

---

### 1.2. Download

Defina a versão utilizada:

```bash
export PNETCDF_VERSION=1.12.3
```

Baixe o código-fonte:

```bash
wget https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz
```

Extraia o arquivo:

```bash
tar xzf pnetcdf-${PNETCDF_VERSION}.tar.gz
```

Entre no diretório:

```bash
cd pnetcdf-${PNETCDF_VERSION}
```

---

### 1.3. Configuração

O PnetCDF será instalado em:

```text
/dependencias/pnetcdf
```

Configure utilizando os compiladores MPI:

```bash
CC=mpicc \
CXX=mpicxx \
FC=mpif90 \
./configure \
    --prefix=/dependencias/pnetcdf \
    --enable-fortran
```

As principais opções são:

| Configuração       | Função                             |
| ------------------ | ---------------------------------- |
| `CC=mpicc`         | Compilador C com suporte MPI       |
| `CXX=mpicxx`       | Compilador C++ com suporte MPI     |
| `FC=mpif90`        | Compilador Fortran com suporte MPI |
| `--prefix`         | Define o diretório de instalação   |
| `--enable-fortran` | Habilita a interface Fortran       |

A opção:

```bash
--enable-fortran
```

é necessária para disponibilizar a interface Fortran do PnetCDF, utilizada posteriormente por componentes que dependem dessa interface.

---

### 1.4. Compilação

Compile o PnetCDF:

```bash
make -j$(nproc)
```

Execute os testes:

```bash
make check
```

Os testes permitem verificar se a biblioteca foi compilada corretamente antes da instalação.

---

### 1.5. Instalação

Instale a biblioteca:

```bash
make install
```

Os arquivos serão instalados em:

```text
/dependencias/pnetcdf
```

A estrutura será semelhante a:

```text
/dependencias/pnetcdf/
├── bin/
├── include/
├── lib/
└── share/
```

Os principais diretórios utilizados posteriormente são:

```text
/dependencias/pnetcdf/include
/dependencias/pnetcdf/lib
```

---

### 1.6. Configuração do ambiente

Defina o diretório de instalação:

```bash
export PNETCDF=/dependencias/pnetcdf
```

Adicione os executáveis ao `PATH`:

```bash
export PATH="${PNETCDF}/bin:${PATH}"
```

Adicione as bibliotecas ao `LD_LIBRARY_PATH`:

```bash
export LD_LIBRARY_PATH="${PNETCDF}/lib:${LD_LIBRARY_PATH}"
```

Para compilação de outras dependências, podem ser utilizados:

```bash
export CPPFLAGS="-I${PNETCDF}/include"
export LDFLAGS="-L${PNETCDF}/lib"
```

---

### 1.7. Verificação

Verifique os arquivos instalados:

```bash
ls /dependencias/pnetcdf/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/pnetcdf/lib
```

O PnetCDF também fornece a ferramenta `pnetcdf-config`, que pode ser utilizada para consultar informações da instalação:

```bash
pnetcdf-config --all
```

Caso disponível, verifique a versão:

```bash
pnetcdf-config --version
```

---

# 2. Instalação com Docker

No ambiente Docker, o PnetCDF é compilado automaticamente durante a construção da imagem.

A versão é definida no início do `Dockerfile`:

```dockerfile
ARG PNETCDF_VERSION=1.12.3
```

A instalação é realizada em:

```text
/dependencias/pnetcdf
```

---

## 2.1. Compilação no Dockerfile

O bloco utilizado no seu `Dockerfile` é:

```dockerfile
RUN cd /build && \
    wget https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz && \
    tar xzf pnetcdf-${PNETCDF_VERSION}.tar.gz && \
    cd pnetcdf-${PNETCDF_VERSION} && \
    CC=mpicc \
    CXX=mpicxx \
    FC=mpif90 \
    ./configure \
        --prefix=/dependencias/pnetcdf \
        --enable-fortran && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/pnetcdf*
```

O processo executa:

```text
Download
   ↓
Extração
   ↓
Configuração
   ↓
Compilação
   ↓
Instalação
   ↓
Remoção dos arquivos temporários
```

---

## 2.2. Compiladores MPI

O `Dockerfile` utiliza:

```dockerfile
CC=mpicc
CXX=mpicxx
FC=mpif90
```

Esses wrappers permitem que o PnetCDF seja compilado utilizando a implementação MPI instalada no container.

A relação é:

```text
mpicc
  └── C + MPI

mpicxx
  └── C++ + MPI

mpif90
  └── Fortran + MPI
```

O suporte MPI é fundamental para o funcionamento do PnetCDF, pois sua finalidade é fornecer operações de I/O paralelas.

---

## 2.3. Variáveis de ambiente

No seu `Dockerfile`, o diretório do PnetCDF é disponibilizado através de:

```dockerfile
ENV PNETCDF=/dependencias/pnetcdf
```

Os executáveis são adicionados ao `PATH`:

```dockerfile
ENV PATH="/dependencias/pnetcdf/bin:${PATH}"
```

E as bibliotecas são adicionadas ao `LD_LIBRARY_PATH`:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/pnetcdf/lib:${LD_LIBRARY_PATH}"
```

Isso permite que outras aplicações e bibliotecas encontrem o PnetCDF durante a compilação e execução.

---

## 2.4. Construção da imagem

Com o bloco do PnetCDF presente no `Dockerfile`:

```bash
docker build -t mpas-pnetcdf .
```

Durante o processo de construção, o Docker realizará automaticamente o download, a compilação e a instalação.

---

## 2.5. Verificação no container

Execute um shell dentro do container:

```bash
docker run --rm -it mpas-pnetcdf bash
```

Verifique os arquivos de header:

```bash
ls /dependencias/pnetcdf/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/pnetcdf/lib
```

E consulte as informações da instalação:

```bash
pnetcdf-config --all
```

---

# 3. Relação com o MPAS

O PnetCDF faz parte da infraestrutura de I/O paralelo utilizada pelo MPAS através do **PIO (Parallel I/O)**.

A cadeia de dependências pode ser representada como:

```text
zlib
  ↓
HDF5
  ↓
NetCDF-C
  ↓
NetCDF-Fortran
  ↓
        ┌──────────────┐
        │     PIO      │
        └──────┬───────┘
               │
       ┌───────┴────────┐
       ▼                ▼
   NetCDF-4          PnetCDF
       │                │
       └───────┬────────┘
               ▼
              MPAS
```

O PnetCDF não substitui o NetCDF-C ou o NetCDF-Fortran. Ele fornece uma implementação específica para **I/O paralelo baseado no formato NetCDF clássico**, enquanto o NetCDF-4 utiliza HDF5 como backend.

O PIO fornece uma camada de abstração que permite ao MPAS utilizar diferentes mecanismos de I/O, incluindo NetCDF e PnetCDF.

---

# 4. Resumo

| Item               | Configuração            |
| ------------------ | ----------------------- |
| Versão             | `1.12.3`                |
| Linguagens         | C, C++ e Fortran        |
| Compilador C       | `mpicc`                 |
| Compilador C++     | `mpicxx`                |
| Compilador Fortran | `mpif90`                |
| MPI                | Habilitado              |
| Fortran            | Habilitado              |
| Diretório          | `/dependencias/pnetcdf` |
| Build              | `make`                  |
| Instalação         | `make install`          |
| Utilização no MPAS | Através do PIO          |

A instalação manual e a instalação via Docker utilizam a mesma versão (`1.12.3`) e o mesmo diretório de instalação. No Docker, o processo é automatizado pelo `Dockerfile`, garantindo que o PnetCDF seja compilado com a mesma implementação MPI utilizada pelas demais dependências do ambiente.

# Instalação do NetCDF-Fortran

## 1. Instalação sem Docker

O **NetCDF-Fortran** fornece a interface Fortran para a biblioteca NetCDF. No ambiente do MPAS, ele é utilizado pelos componentes escritos em Fortran que precisam acessar arquivos no formato NetCDF.

O **NetCDF-C deve estar instalado previamente**, pois o NetCDF-Fortran utiliza sua instalação como base.

Neste ambiente, o NetCDF-C está instalado em:

```text
/dependencias/netcdf
```

O NetCDF-Fortran será instalado no mesmo diretório.

---

## 1.1. Dependências

Em sistemas baseados em Ubuntu, instale as ferramentas necessárias:

```bash
sudo apt-get update
sudo apt-get install -y wget tar build-essential \
    gcc gfortran make
```

Também é necessário possuir o MPI:

```bash
sudo apt-get install -y mpich libmpich-dev
```

Verifique o compilador Fortran MPI:

```bash
mpif90 --version
```

O NetCDF-C deve estar instalado e acessível em:

```text
/dependencias/netcdf
```

Verifique:

```bash
ls /dependencias/netcdf/include
ls /dependencias/netcdf/lib
```

---

## 1.2. Download

Defina a versão utilizada:

```bash
export NETCDF_FORTRAN_VERSION=4.6.2
```

Baixe o código-fonte:

```bash
wget https://downloads.unidata.ucar.edu/netcdf-fortran/${NETCDF_FORTRAN_VERSION}/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz
```

Extraia o arquivo:

```bash
tar xzf netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz
```

Entre no diretório:

```bash
cd netcdf-fortran-${NETCDF_FORTRAN_VERSION}
```

---

## 1.3. Configuração

O NetCDF-Fortran será instalado no mesmo prefixo utilizado pelo NetCDF-C:

```text
/dependencias/netcdf
```

Configure a compilação:

```bash
CPPFLAGS="-I/dependencias/netcdf/include" \
LDFLAGS="-L/dependencias/netcdf/lib" \
CC=mpicc \
FC=mpif90 \
./configure \
    --prefix=/dependencias/netcdf
```

As principais configurações são:

| Configuração | Função                                  |
| ------------ | --------------------------------------- |
| `CC=mpicc`   | Define o compilador C MPI               |
| `FC=mpif90`  | Define o compilador Fortran MPI         |
| `CPPFLAGS`   | Localização dos headers do NetCDF-C     |
| `LDFLAGS`    | Localização das bibliotecas do NetCDF-C |
| `--prefix`   | Define o diretório de instalação        |

O ponto principal é que:

```bash
-I/dependencias/netcdf/include
```

permite encontrar os headers do NetCDF-C, enquanto:

```bash
-L/dependencias/netcdf/lib
```

permite localizar suas bibliotecas.

---

## 1.4. Compilação

Após a configuração, compile:

```bash
make -j$(nproc)
```

Execute os testes:

```bash
make check
```

Os testes verificam o funcionamento da interface Fortran antes da instalação.

---

## 1.5. Instalação

Instale:

```bash
make install
```

Como o mesmo prefixo é utilizado pelo NetCDF-C e pelo NetCDF-Fortran, os arquivos serão adicionados à instalação existente:

```text
/dependencias/netcdf/
├── bin/
├── include/
├── lib/
└── share/
```

As bibliotecas Fortran estarão principalmente em:

```text
/dependencias/netcdf/lib
```

---

## 1.6. Configuração do ambiente

Defina o diretório do NetCDF:

```bash
export NETCDF=/dependencias/netcdf
```

Adicione os executáveis ao `PATH`:

```bash
export PATH="${NETCDF}/bin:${PATH}"
```

Adicione as bibliotecas ao `LD_LIBRARY_PATH`:

```bash
export LD_LIBRARY_PATH="${NETCDF}/lib:${LD_LIBRARY_PATH}"
```

---

## 1.7. Verificação

A ferramenta `nf-config` permite verificar a instalação do NetCDF-Fortran.

Verifique a versão:

```bash
nf-config --version
```

Verifique a configuração completa:

```bash
nf-config --all
```

Também podem ser verificadas as bibliotecas:

```bash
ls /dependencias/netcdf/lib
```

e os módulos Fortran:

```bash
ls /dependencias/netcdf/include
```

O comando `nf-config --all` é particularmente útil para verificar os compiladores, flags e diretórios utilizados durante a instalação.

---

# 2. Instalação com Docker

No ambiente Docker, o NetCDF-Fortran é compilado automaticamente durante a construção da imagem.

A versão utilizada é definida no `Dockerfile`:

```dockerfile
ARG NETCDF_FORTRAN_VERSION=4.6.2
```

O NetCDF-C deve ter sido instalado anteriormente em:

```text
/dependencias/netcdf
```

O NetCDF-Fortran será instalado no mesmo diretório.

---

## 2.1. Compilação no Dockerfile

O bloco utilizado para a instalação é:

```dockerfile
RUN cd /build && \
    wget https://downloads.unidata.ucar.edu/netcdf-fortran/${NETCDF_FORTRAN_VERSION}/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz && \
    tar xzf netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz && \
    cd netcdf-fortran-${NETCDF_FORTRAN_VERSION} && \
    CPPFLAGS="-I/dependencias/netcdf/include" \
    LDFLAGS="-L/dependencias/netcdf/lib" \
    CC=mpicc \
    FC=mpif90 \
    ./configure \
        --prefix=/dependencias/netcdf && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/netcdf-fortran*
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

## 2.2. Dependência do NetCDF-C

O NetCDF-Fortran utiliza a instalação do NetCDF-C:

```text
/dependencias/netcdf
```

Por isso, durante a configuração são informados:

```bash
CPPFLAGS="-I/dependencias/netcdf/include"
```

e:

```bash
LDFLAGS="-L/dependencias/netcdf/lib"
```

A relação entre os componentes é:

```text
zlib
  ↓
HDF5
  ↓
NetCDF-C
  ↓
NetCDF-Fortran
```

O NetCDF-Fortran não deve ser compilado antes do NetCDF-C.

---

## 2.3. Compiladores

No `Dockerfile`, são utilizados os wrappers MPI:

```dockerfile
CC=mpicc
FC=mpif90
```

O `mpicc` fornece o ambiente de compilação C baseado em MPI, enquanto o `mpif90` fornece o ambiente de compilação Fortran baseado em MPI.

O compilador Fortran é especialmente importante porque o NetCDF-Fortran contém código Fortran.

---

## 2.4. Construção da imagem

Com o bloco de instalação presente no `Dockerfile`:

```bash
docker build -t mpas-netcdf-fortran .
```

Durante o `docker build`, o NetCDF-Fortran será automaticamente baixado, compilado e instalado.

---

## 2.5. Verificação no container

Execute um shell dentro do container:

```bash
docker run --rm -it mpas-netcdf-fortran bash
```

Verifique a versão:

```bash
nf-config --version
```

Verifique a configuração:

```bash
nf-config --all
```

Verifique as bibliotecas:

```bash
ls /dependencias/netcdf/lib
```

E os arquivos de interface:

```bash
ls /dependencias/netcdf/include
```

---

# 3. Relação com o MPAS

O NetCDF-Fortran é uma dependência importante para o ambiente do MPAS porque o modelo possui componentes escritos em **Fortran** que realizam operações de entrada e saída através da API NetCDF.

A cadeia de dependências utilizada neste ambiente é:

```text
zlib
  ↓
HDF5
  ↓
NetCDF-C
  ↓
NetCDF-Fortran
  ↓
PIO
  ↓
MPAS
```

O NetCDF-Fortran fornece a camada Fortran sobre o NetCDF-C. Dessa forma, os códigos Fortran podem utilizar as funcionalidades da biblioteca NetCDF sem acessar diretamente a implementação em C.

---

# 4. Resumo

| Item                    | Configuração           |
| ----------------------- | ---------------------- |
| Versão                  | `4.6.2`                |
| Linguagem               | Fortran                |
| Compilador              | `mpif90`               |
| Dependência principal   | NetCDF-C               |
| Diretório do NetCDF-C   | `/dependencias/netcdf` |
| Diretório de instalação | `/dependencias/netcdf` |
| Build                   | `make`                 |
| Instalação              | `make install`         |
| Verificação             | `nf-config`            |

A instalação manual e a instalação via Docker utilizam a mesma versão e o mesmo diretório de instalação. A diferença é que, no Docker, todo o processo é automatizado pelo `Dockerfile`.

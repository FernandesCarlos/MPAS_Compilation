# Instalação do HDF5

## 1. Instalação sem Docker

A instalação manual do HDF5 consiste em baixar o código-fonte, configurar a compilação com suporte a **MPI**, **Fortran** e **zlib**, compilar e instalar em um diretório definido.

### 1.1. Dependências

Em sistemas baseados em Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y wget tar build-essential \
    gcc gfortran make mpich libmpich-dev
```

A zlib deve estar previamente instalada, pois o HDF5 será configurado para utilizá-la.

Considerando a instalação utilizada neste ambiente:

```text
/dependencias/zlib
```

Também é necessário que o MPI esteja disponível através de `mpicc` e `mpif90`.

Verifique:

```bash
mpicc --version
mpif90 --version
```

### 1.2. Download

Defina a versão do HDF5:

```bash
export HDF5_VERSION=1.14.6
```

Baixe o código-fonte:

```bash
wget https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/hdf5-${HDF5_VERSION}.tar.gz
```

Extraia:

```bash
tar xzf hdf5-${HDF5_VERSION}.tar.gz
```

Entre no diretório:

```bash
cd hdf5-${HDF5_VERSION}
```

### 1.3. Configuração

Neste ambiente, o HDF5 é instalado em:

```text
/dependencias/hdf5
```

A configuração utilizada é:

```bash
CC=mpicc FC=mpif90 ./configure \
    --enable-parallel \
    --enable-fortran \
    --with-zlib=/dependencias/zlib \
    --prefix=/dependencias/hdf5
```

As principais opções são:

| Opção               | Função                           |
| ------------------- | -------------------------------- |
| `CC=mpicc`          | Utiliza o compilador C MPI       |
| `FC=mpif90`         | Utiliza o compilador Fortran MPI |
| `--enable-parallel` | Habilita suporte a HDF5 paralelo |
| `--enable-fortran`  | Habilita a interface Fortran     |
| `--with-zlib`       | Define a instalação da zlib      |
| `--prefix`          | Define o diretório de instalação |

O parâmetro:

```bash
--with-zlib=/dependencias/zlib
```

é importante porque informa ao HDF5 qual instalação da zlib deve ser utilizada.

### 1.4. Compilação

Compile o HDF5:

```bash
make -j$(nproc)
```

Opcionalmente, execute os testes:

```bash
make check
```

### 1.5. Instalação

Instale:

```bash
make install
```

A instalação resultará em uma estrutura semelhante a:

```text
/dependencias/hdf5/
├── bin/
├── include/
├── lib/
└── share/
```

Os arquivos principais estarão em:

```text
/dependencias/hdf5/include
/dependencias/hdf5/lib
```

### 1.6. Configuração do ambiente

Defina o caminho da instalação:

```bash
export HDF5_ROOT=/dependencias/hdf5
```

Adicione os diretórios ao ambiente:

```bash
export PATH="${HDF5_ROOT}/bin:${PATH}"
export LD_LIBRARY_PATH="${HDF5_ROOT}/lib:${LD_LIBRARY_PATH}"
```

Para facilitar a compilação das próximas dependências:

```bash
export CPPFLAGS="-I${HDF5_ROOT}/include"
export LDFLAGS="-L${HDF5_ROOT}/lib"
```

### 1.7. Verificação

Verifique a versão instalada:

```bash
h5cc -showconfig
```

Para verificar especificamente o suporte a paralelismo:

```bash
h5pcc -showconfig
```

Na saída, deve ser possível identificar que o HDF5 foi compilado com suporte a **Parallel HDF5**.

Também é possível verificar os arquivos instalados:

```bash
ls /dependencias/hdf5/include
```

e:

```bash
ls /dependencias/hdf5/lib
```

---

## 2. Instalação com Docker

No ambiente Docker, o HDF5 é compilado automaticamente durante a construção da imagem.

A versão é definida através de um argumento:

```dockerfile
ARG HDF5_VERSION=1.14.6
```

A zlib deve ter sido instalada anteriormente em:

```text
/dependencias/zlib
```

### 2.1. Compilação no Dockerfile

O bloco utilizado para instalar o HDF5 é:

```dockerfile
RUN cd /build && \
    wget https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/hdf5-${HDF5_VERSION}.tar.gz && \
    tar xzf hdf5-${HDF5_VERSION}.tar.gz && \
    cd hdf5-${HDF5_VERSION} && \
    CC=mpicc FC=mpif90 ./configure \
        --enable-parallel \
        --enable-fortran \
        --with-zlib=/dependencias/zlib \
        --prefix=/dependencias/hdf5 && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/hdf5*
```

Nesse processo:

1. o código-fonte do HDF5 é baixado;
2. o arquivo é extraído;
3. `mpicc` é definido como compilador C;
4. `mpif90` é definido como compilador Fortran;
5. o suporte a HDF5 paralelo é habilitado;
6. o suporte à interface Fortran é habilitado;
7. a zlib instalada anteriormente é utilizada;
8. o HDF5 é compilado;
9. o HDF5 é instalado em `/dependencias/hdf5`;
10. os arquivos temporários são removidos.

### 2.2. Variáveis de ambiente

Após a instalação, o diretório das bibliotecas pode ser disponibilizado através do `LD_LIBRARY_PATH`:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/hdf5/lib:/dependencias/zlib/lib:${LD_LIBRARY_PATH}"
```

Também pode ser definido:

```dockerfile
ENV HDF5_ROOT=/dependencias/hdf5
```

E o diretório dos executáveis pode ser adicionado ao `PATH`:

```dockerfile
ENV PATH="/dependencias/hdf5/bin:${PATH}"
```

### 2.3. Construção da imagem

Com o HDF5 incluído no `Dockerfile`:

```bash
docker build -t mpas-hdf5 .
```

Durante o processo, o Docker executará automaticamente as etapas de compilação.

### 2.4. Verificação

Executar um shell dentro do container:

```bash
docker run --rm -it mpas-hdf5 bash
```

Verificar a configuração:

```bash
h5cc -showconfig
```

Para verificar o suporte paralelo:

```bash
h5pcc -showconfig
```

Também podem ser verificadas as bibliotecas:

```bash
ls /dependencias/hdf5/lib
```

e os headers:

```bash
ls /dependencias/hdf5/include
```

---

## 3. Comparação dos métodos

| Método      | Característica                                 |
| ----------- | ---------------------------------------------- |
| Sem Docker  | Compilação diretamente no sistema              |
| Com Docker  | Compilação automatizada durante `docker build` |
| Versão      | `1.14.6`                                       |
| Diretório   | `/dependencias/hdf5`                           |
| MPI         | `mpicc` / `mpif90`                             |
| Paralelismo | Habilitado                                     |
| Fortran     | Habilitado                                     |
| zlib        | Utilizada em `/dependencias/zlib`              |
| Build       | `make`                                         |
| Instalação  | `make install`                                 |

Em ambos os métodos, o HDF5 é compilado com **MPI, Fortran e suporte à zlib**, mantendo a mesma organização de diretórios utilizada no ambiente Docker do MPAS.

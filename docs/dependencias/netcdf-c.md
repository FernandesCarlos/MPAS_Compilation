# Instalação do NetCDF-C

## 1. Instalação sem Docker

O **NetCDF-C** é a implementação da biblioteca NetCDF em C. No ambiente do MPAS, ele é utilizado com suporte ao **NetCDF-4**, utilizando o **HDF5** como backend de armazenamento.

Para esta instalação, o HDF5 e a zlib devem estar previamente instalados em:

```text
/dependencias/hdf5
/dependencias/zlib
```

O NetCDF-C será instalado em:

```text
/dependencias/netcdf
```

### 1.1. Dependências

Em sistemas baseados em Ubuntu, instale as ferramentas necessárias:

```bash
sudo apt-get update
sudo apt-get install -y wget tar build-essential gcc make
```

Também é necessário possuir o MPI instalado:

```bash
sudo apt-get install -y mpich libmpich-dev
```

Verifique o compilador MPI:

```bash
mpicc --version
```

O HDF5 e a zlib devem estar disponíveis antes da compilação do NetCDF-C.

---

### 1.2. Download

Defina a versão utilizada:

```bash
export NETCDF_C_VERSION=4.9.3
```

Baixe o código-fonte:

```bash
wget https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_C_VERSION}/netcdf-c-${NETCDF_C_VERSION}.tar.gz
```

Extraia o arquivo:

```bash
tar xzf netcdf-c-${NETCDF_C_VERSION}.tar.gz
```

Entre no diretório:

```bash
cd netcdf-c-${NETCDF_C_VERSION}
```

---

### 1.3. Configuração

O NetCDF-C será instalado em:

```text
/dependencias/netcdf
```

Configure a compilação:

```bash
CPPFLAGS="-I/dependencias/hdf5/include -I/dependencias/zlib/include" \
LDFLAGS="-L/dependencias/hdf5/lib -L/dependencias/zlib/lib" \
CC=mpicc ./configure \
    --prefix=/dependencias/netcdf \
    --disable-dap \
    --enable-netcdf4 \
    --disable-libxml2
```

As principais configurações são:

| Configuração        | Função                                          |
| ------------------- | ----------------------------------------------- |
| `CC=mpicc`          | Utiliza o compilador C do MPI                   |
| `--prefix`          | Define o diretório de instalação                |
| `--enable-netcdf4`  | Habilita suporte ao NetCDF-4/HDF5               |
| `--disable-dap`     | Desabilita o suporte a DAP                      |
| `--disable-libxml2` | Desabilita a dependência de libxml2             |
| `CPPFLAGS`          | Define onde estão os headers do HDF5 e zlib     |
| `LDFLAGS`           | Define onde estão as bibliotecas do HDF5 e zlib |

O parâmetro mais importante para a integração com o HDF5 é:

```bash
--enable-netcdf4
```

Ele permite que o NetCDF-C seja construído com suporte ao formato NetCDF-4 baseado em HDF5.

---

### 1.4. Compilação

Após a configuração, compile:

```bash
make -j$(nproc)
```

Os testes podem ser executados com:

```bash
make check
```

A execução dos testes permite verificar se a biblioteca foi compilada corretamente antes da instalação.

---

### 1.5. Instalação

Instale o NetCDF-C:

```bash
make install
```

Os arquivos serão instalados em:

```text
/dependencias/netcdf
```

A estrutura esperada é:

```text
/dependencias/netcdf/
├── bin/
├── include/
├── lib/
└── share/
```

Os principais diretórios são:

```text
/dependencias/netcdf/include
/dependencias/netcdf/lib
```

---

### 1.6. Configuração do ambiente

Defina a variável que representa a instalação do NetCDF:

```bash
export NETCDF=/dependencias/netcdf
```

Adicione os executáveis ao `PATH`:

```bash
export PATH="${NETCDF}/bin:${PATH}"
```

Adicione as bibliotecas ao caminho de execução:

```bash
export LD_LIBRARY_PATH="${NETCDF}/lib:${LD_LIBRARY_PATH}"
```

---

### 1.7. Verificação

Verifique a versão instalada:

```bash
nc-config --version
```

Para obter todas as informações de configuração:

```bash
nc-config --all
```

Verifique os headers:

```bash
ls /dependencias/netcdf/include
```

E as bibliotecas:

```bash
ls /dependencias/netcdf/lib
```

O comando:

```bash
nc-config --all
```

é particularmente útil para verificar se o NetCDF-C foi compilado com suporte ao NetCDF-4 e quais caminhos de bibliotecas estão sendo utilizados.

---

# 2. Instalação com Docker

No ambiente Docker, o NetCDF-C é compilado automaticamente durante a construção da imagem.

A versão é definida no início do `Dockerfile`:

```dockerfile
ARG NETCDF_C_VERSION=4.9.3
```

O HDF5 e a zlib são instalados anteriormente nos diretórios:

```text
/dependencias/hdf5
/dependencias/zlib
```

O NetCDF-C será instalado em:

```text
/dependencias/netcdf
```

---

## 2.1. Compilação no Dockerfile

O bloco utilizado para a instalação é:

```dockerfile
RUN cd /build && \
    wget https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_C_VERSION}/netcdf-c-${NETCDF_C_VERSION}.tar.gz && \
    tar xzf netcdf-c-${NETCDF_C_VERSION}.tar.gz && \
    cd netcdf-c-${NETCDF_C_VERSION} && \
    CPPFLAGS="-I/dependencias/hdf5/include -I/dependencias/zlib/include" \
    LDFLAGS="-L/dependencias/hdf5/lib -L/dependencias/zlib/lib" \
    CC=mpicc ./configure \
        --prefix=/dependencias/netcdf \
        --disable-dap \
        --enable-netcdf4 \
        --disable-libxml2 && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/netcdf-c*
```

O processo executa as seguintes etapas:

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

## 2.2. Dependências utilizadas

Durante a configuração, o NetCDF-C recebe os caminhos do HDF5:

```text
-I/dependencias/hdf5/include
-L/dependencias/hdf5/lib
```

e da zlib:

```text
-I/dependencias/zlib/include
-L/dependencias/zlib/lib
```

Isso permite que o compilador encontre os headers e bibliotecas necessários.

A relação é:

```text
zlib
  ↓
HDF5
  ↓
NetCDF-C
```

---

## 2.3. Variáveis de ambiente

No `Dockerfile`, o diretório do NetCDF-C é disponibilizado através de:

```dockerfile
ENV NETCDF=/dependencias/netcdf
```

O diretório de executáveis é adicionado ao `PATH`:

```dockerfile
ENV PATH="/dependencias/netcdf/bin:${PATH}"
```

As bibliotecas são disponibilizadas através do:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/netcdf/lib:/dependencias/hdf5/lib:/dependencias/zlib/lib:${LD_LIBRARY_PATH}"
```

Isso permite que os executáveis encontrem as bibliotecas compartilhadas necessárias durante a execução.

---

## 2.4. Construção da imagem

Com o bloco do NetCDF-C presente no `Dockerfile`, a imagem pode ser construída utilizando:

```bash
docker build -t mpas-netcdf-c .
```

Durante o `docker build`, o NetCDF-C será automaticamente baixado, compilado e instalado.

---

## 2.5. Verificação no container

Execute um terminal dentro do container:

```bash
docker run --rm -it mpas-netcdf-c bash
```

Verifique a versão:

```bash
nc-config --version
```

Verifique a configuração completa:

```bash
nc-config --all
```

Verifique os headers:

```bash
ls /dependencias/netcdf/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/netcdf/lib
```

---

# 3. Relação com as dependências do MPAS

A instalação do NetCDF-C ocorre após a instalação do HDF5 e da zlib:

```text
zlib
  │
  ▼
HDF5
  │
  ▼
NetCDF-C
```

O NetCDF-C utiliza o HDF5 para fornecer suporte ao **NetCDF-4**. A zlib é utilizada pelo HDF5 para os mecanismos de compressão baseados em DEFLATE.

No stack de bibliotecas utilizado pelo MPAS, o NetCDF-C constitui uma das camadas responsáveis pelo acesso aos arquivos de dados científicos.

---

# 4. Resumo

| Item             | Configuração           |
| ---------------- | ---------------------- |
| Versão           | `4.9.3`                |
| Linguagem        | C                      |
| Compilador       | `mpicc`                |
| Backend NetCDF-4 | HDF5                   |
| Compressão       | zlib                   |
| Instalação       | `/dependencias/netcdf` |
| NetCDF-4         | Habilitado             |
| DAP              | Desabilitado           |
| libxml2          | Desabilitado           |
| Build            | `make`                 |
| Instalação       | `make install`         |

A instalação manual e a instalação via Docker utilizam a mesma configuração. A principal diferença é que, no Docker, todas as etapas são declaradas no `Dockerfile` e executadas automaticamente durante a construção da imagem.

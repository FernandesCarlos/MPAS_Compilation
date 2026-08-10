# Instalação do METIS

## 1. Instalação sem Docker

O **METIS** é uma biblioteca para **particionamento de grafos e decomposição de domínios**. No ambiente do MPAS, ele é utilizado para auxiliar na divisão do domínio computacional em partições que podem ser distribuídas entre diferentes processos MPI.

O METIS possui como dependência o **GKlib**, que fornece funções auxiliares utilizadas durante sua compilação.

Neste ambiente, ambos serão instalados em:

```text
/dependencias/metis
```

A relação é:

```text
GKlib
  ↓
METIS
  ↓
Particionamento do domínio
  ↓
MPAS + MPI
```

---

## 1.1. Dependências

Em sistemas baseados em Ubuntu, instale:

```bash
sudo apt-get update
sudo apt-get install -y \
    git \
    build-essential \
    gcc \
    make
```

Verifique o compilador:

```bash
gcc --version
```

---

## 1.2. Instalação do GKlib

O GKlib deve ser instalado antes do METIS.

Clone o repositório:

```bash
cd /build

git clone --depth 1 https://github.com/KarypisLab/GKlib.git
```

Entre no diretório:

```bash
cd GKlib
```

Configure a compilação:

```bash
make config \
    prefix=/dependencias/metis \
    cc=gcc \
    shared=1
```

As principais opções são:

| Opção      | Função                              |
| ---------- | ----------------------------------- |
| `prefix`   | Define o diretório de instalação    |
| `cc=gcc`   | Utiliza o compilador GCC            |
| `shared=1` | Habilita bibliotecas compartilhadas |

Compile:

```bash
make -j$(nproc)
```

Instale:

```bash
make install
```

Após a instalação, o GKlib estará disponível dentro de:

```text
/dependencias/metis
```

---

# 2. Instalação do METIS

## 2.1. Download

Defina a versão:

```bash
export METIS_VERSION=5.2.1
```

Clone o repositório na versão desejada:

```bash
cd /build

git clone \
    --branch v${METIS_VERSION} \
    --depth 1 \
    https://github.com/KarypisLab/METIS.git
```

Entre no diretório:

```bash
cd METIS
```

---

## 2.2. Configuração

O METIS deve ser configurado para utilizar o GKlib instalado anteriormente:

```bash
make config \
    shared=1 \
    cc=gcc \
    prefix=/dependencias/metis \
    gklib_path=/dependencias/metis
```

As principais opções são:

| Opção        | Função                              |
| ------------ | ----------------------------------- |
| `shared=1`   | Habilita bibliotecas compartilhadas |
| `cc=gcc`     | Define o compilador C               |
| `prefix`     | Define o diretório de instalação    |
| `gklib_path` | Localização do GKlib                |

O parâmetro:

```bash
gklib_path=/dependencias/metis
```

é importante porque informa ao METIS onde encontrar o GKlib instalado anteriormente.

---

## 2.3. Compilação

Compile:

```bash
make -j$(nproc)
```

---

## 2.4. Instalação

Instale:

```bash
make install
```

O METIS será instalado em:

```text
/dependencias/metis
```

A estrutura resultante será semelhante a:

```text
/dependencias/metis/
├── bin/
├── include/
└── lib/
```

Os arquivos principais estarão em:

```text
/dependencias/metis/include
/dependencias/metis/lib
```

---

## 2.5. Configuração do ambiente

Adicione os executáveis ao `PATH`:

```bash
export PATH="/dependencias/metis/bin:${PATH}"
```

Adicione as bibliotecas ao `LD_LIBRARY_PATH`:

```bash
export LD_LIBRARY_PATH="/dependencias/metis/lib:${LD_LIBRARY_PATH}"
```

Para compilação de outras aplicações, também podem ser definidos:

```bash
export CPPFLAGS="-I/dependencias/metis/include"
export LDFLAGS="-L/dependencias/metis/lib"
```

---

## 2.6. Verificação

Verifique os headers:

```bash
ls /dependencias/metis/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/metis/lib
```

Também é possível verificar os executáveis:

```bash
ls /dependencias/metis/bin
```

As bibliotecas compartilhadas do METIS e do GKlib devem estar disponíveis no diretório:

```text
/dependencias/metis/lib
```

---

# 3. Instalação com Docker

No `Dockerfile`, o GKlib e o METIS são compilados em sequência.

A versão do METIS é definida por:

```dockerfile
ARG METIS_VERSION=5.2.1
```

O diretório utilizado para a instalação é:

```text
/dependencias/metis
```

---

## 3.1. Compilação do GKlib

O bloco utilizado no `Dockerfile` é:

```dockerfile
RUN cd /build && \
    git clone --depth 1 https://github.com/KarypisLab/GKlib.git && \
    cd GKlib && \
    make config \
        prefix=/dependencias/metis \
        cc=gcc \
        shared=1 && \
    make -j$(nproc) && \
    make install
```

O processo é:

```text
Clone do GKlib
      ↓
Configuração
      ↓
Compilação
      ↓
Instalação
```

O GKlib é instalado em:

```text
/dependencias/metis
```

---

## 3.2. Compilação do METIS

Depois da instalação do GKlib, o METIS é obtido:

```dockerfile
RUN cd /build && \
    git clone \
        --branch v${METIS_VERSION} \
        --depth 1 \
        https://github.com/KarypisLab/METIS.git
```

Em seguida, é realizada a configuração:

```dockerfile
cd METIS && \
make config \
    shared=1 \
    cc=gcc \
    prefix=/dependencias/metis \
    gklib_path=/dependencias/metis
```

Depois:

```dockerfile
make -j$(nproc) && \
make install
```

Por fim, os arquivos temporários são removidos:

```dockerfile
rm -rf /build/GKlib /build/METIS
```

---

## 3.3. Bloco completo do Dockerfile

A configuração utilizada no seu ambiente pode ser representada por:

```dockerfile
RUN cd /build && \
    git clone --depth 1 https://github.com/KarypisLab/GKlib.git && \
    cd GKlib && \
    make config \
        prefix=/dependencias/metis \
        cc=gcc \
        shared=1 && \
    make -j$(nproc) && \
    make install && \
    cd /build && \
    git clone \
        --branch v${METIS_VERSION} \
        --depth 1 \
        https://github.com/KarypisLab/METIS.git && \
    cd METIS && \
    make config \
        shared=1 \
        cc=gcc \
        prefix=/dependencias/metis \
        gklib_path=/dependencias/metis && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/GKlib /build/METIS
```

---

## 3.4. Variáveis de ambiente

No seu `Dockerfile`, o diretório de bibliotecas é adicionado ao `LD_LIBRARY_PATH`:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/metis/lib:${LD_LIBRARY_PATH}"
```

O diretório de executáveis é adicionado ao `PATH`:

```dockerfile
ENV PATH="/dependencias/metis/bin:${PATH}"
```

Dessa forma, os programas e bibliotecas do METIS ficam disponíveis para os processos executados dentro do container.

---

## 3.5. Construção da imagem

Com o METIS incluído no `Dockerfile`:

```bash
docker build -t mpas-metis .
```

O Docker realizará automaticamente:

```text
GKlib
  ↓
METIS
  ↓
Instalação em /dependencias/metis
```

---

## 3.6. Verificação no container

Execute um shell:

```bash
docker run --rm -it mpas-metis bash
```

Verifique:

```bash
ls /dependencias/metis/include
```

```bash
ls /dependencias/metis/lib
```

E:

```bash
ls /dependencias/metis/bin
```

---

# 4. Relação com o MPAS

O METIS não faz parte do sistema de I/O do MPAS. Sua função está relacionada ao **particionamento do domínio computacional**.

O MPAS utiliza uma malha que precisa ser dividida entre os processos MPI durante a execução paralela.

O METIS pode ser utilizado para encontrar uma divisão do grafo da malha em múltiplas partições, buscando reduzir a comunicação entre os processos.

De forma simplificada:

```text
Malha do MPAS
      │
      ▼
Representação como grafo
      │
      ▼
    METIS
      │
      ▼
Particionamento
      │
      ├── Processo MPI 0
      ├── Processo MPI 1
      ├── Processo MPI 2
      └── ...
```

Um particionamento adequado pode reduzir a quantidade de comunicação entre processos e melhorar o balanceamento da carga computacional.

---

# 5. Relação com o restante do ambiente

Diferentemente das bibliotecas de I/O, o METIS pertence à parte de **particionamento/decomposição do domínio**.

Uma organização conceitual das dependências do seu ambiente é:

```text
                 MPAS
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
      PIO                 METIS
        │                   │
        │             Particionamento
        │                   │
        ▼                   ▼
 NetCDF / PnetCDF       Domínio MPAS
        │
        ▼
       HDF5
        │
        ▼
       zlib
```

O **GKlib** é uma dependência direta da compilação do METIS:

```text
GKlib
  ↓
METIS
  ↓
Particionamento
  ↓
MPAS
```

---

# 6. Resumo

| Item                       | Configuração               |
| -------------------------- | -------------------------- |
| Biblioteca                 | METIS                      |
| Versão                     | `5.2.1`                    |
| Dependência                | GKlib                      |
| Compilador                 | GCC                        |
| Linguagem                  | C                          |
| Bibliotecas compartilhadas | Habilitadas                |
| GKlib                      | Habilitado                 |
| Diretório                  | `/dependencias/metis`      |
| Build                      | `make`                     |
| Configuração               | `make config`              |
| Instalação                 | `make install`             |
| Função no MPAS             | Particionamento do domínio |
| Categoria                  | Particionamento, não I/O   |

O METIS deve ser compilado após o GKlib, pois o parâmetro `gklib_path=/dependencias/metis` utilizado na configuração aponta para a instalação do GKlib. No ambiente Docker, essa ordem é automaticamente garantida pelo `Dockerfile`.

# Instalação do Jasper

## 1. Instalação sem Docker

O **Jasper** é uma biblioteca utilizada para processamento de imagens no formato **JPEG-2000**. No ambiente do MPAS, sua principal utilização está relacionada ao **WPS (WRF Preprocessing System)**, especialmente no processamento de dados meteorológicos no formato **GRIB2**.

No seu ambiente, o Jasper é utilizado pelo `ungrib`, responsável pela conversão e extração de dados meteorológicos que posteriormente podem ser utilizados no processamento do MPAS.

A biblioteca será instalada em:

```text id="j7q8vx"
/dependencias/jasper
```

A relação pode ser representada como:

```text id="7e9n0v"
Dados GRIB2
    ↓
  WPS
    ↓
 ungrib
    ↓
 Jasper
    ↓
Dados meteorológicos processados
    ↓
 MPAS
```

---

## 1.1. Dependências

Em sistemas baseados em Ubuntu, instale as ferramentas necessárias:

```bash id="k0c9f3"
sudo apt-get update
sudo apt-get install -y \
    wget \
    tar \
    build-essential \
    gcc \
    make
```

Verifique o compilador:

```bash id="v2r1jf"
gcc --version
```

---

## 1.2. Download

No seu ambiente, a versão utilizada é:

```text id="7jz5zn"
1.900.1
```

Defina a versão:

```bash id="y6g5h1"
export JASPER_VERSION=1.900.1
```

Baixe o código-fonte:

```bash id="2x5jjh"
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-${JASPER_VERSION}.tar.gz
```

Extraia:

```bash id="8rxm4p"
tar xzf jasper-${JASPER_VERSION}.tar.gz
```

Entre no diretório:

```bash id="5a6j6j"
cd jasper-${JASPER_VERSION}
```

---

## 1.3. Configuração

O Jasper será instalado em:

```text id="w4m9jy"
/dependencias/jasper
```

No seu `Dockerfile`, são utilizados os seguintes parâmetros de compilação:

```bash id="r4z9d0"
CFLAGS="-O2 -fPIC \
-Wno-implicit-function-declaration \
-Wno-incompatible-pointer-types \
-Wno-implicit-int" \
./configure \
    --prefix=/dependencias/jasper
```

O parâmetro:

```bash id="y1k1m6"
--prefix=/dependencias/jasper
```

define o diretório de instalação.

Os parâmetros de `CFLAGS` utilizados no seu ambiente são:

| Flag                                 | Função                                                    |
| ------------------------------------ | --------------------------------------------------------- |
| `-O2`                                | Habilita otimizações do compilador                        |
| `-fPIC`                              | Gera código independente de posição                       |
| `-Wno-implicit-function-declaration` | Desabilita warnings relacionados a declarações implícitas |
| `-Wno-incompatible-pointer-types`    | Desabilita warnings de tipos de ponteiros incompatíveis   |
| `-Wno-implicit-int`                  | Desabilita warnings relacionados a `int` implícito        |

Essas opções são particularmente relevantes porque essa versão do Jasper é antiga em relação aos compiladores modernos.

---

## 1.4. Compilação

Compile:

```bash id="1i4x9q"
make -j$(nproc)
```

A variável:

```bash id="f6k1ak"
$(nproc)
```

permite utilizar os processadores disponíveis para acelerar a compilação.

---

## 1.5. Instalação

Instale:

```bash id="5r5p91"
make install
```

Os arquivos serão instalados em:

```text id="2wck6b"
/dependencias/jasper
```

A estrutura será semelhante a:

```text id="7sm0lh"
/dependencias/jasper/
├── bin/
├── include/
├── lib/
└── share/
```

Os principais diretórios utilizados pelo WPS são:

```text id="p4z8p8"
/dependencias/jasper/include
/dependencias/jasper/lib
```

---

## 1.6. Configuração do ambiente

Defina o diretório de instalação:

```bash id="7h3v7h"
export JASPER=/dependencias/jasper
```

Configure o diretório dos headers:

```bash id="nj8e4w"
export JASPERINC=/dependencias/jasper/include
```

Configure o diretório das bibliotecas:

```bash id="5w8qge"
export JASPERLIB=/dependencias/jasper/lib
```

Adicione as bibliotecas ao caminho de execução:

```bash id="c5q7hs"
export LD_LIBRARY_PATH="${JASPERLIB}:${LD_LIBRARY_PATH}"
```

---

## 1.7. Verificação

Verifique os headers:

```bash id="w9v4y6"
ls /dependencias/jasper/include
```

Verifique as bibliotecas:

```bash id="8m9b17"
ls /dependencias/jasper/lib
```

Também é possível verificar o conteúdo do diretório de instalação:

```bash id="ps7g5v"
find /dependencias/jasper -maxdepth 2 -type f
```

---

# 2. Instalação com Docker

No seu `Dockerfile`, o Jasper é compilado automaticamente durante a construção da imagem.

A versão é definida por:

```dockerfile id="h1t7pn"
ARG JASPER_VERSION=1.900.1
```

O diretório de instalação é:

```text id="q5c3xs"
/dependencias/jasper
```

---

## 2.1. Compilação no Dockerfile

O bloco utilizado no seu `Dockerfile` é:

```dockerfile id="b6p9p3"
RUN cd /build && \
    wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-${JASPER_VERSION}.tar.gz && \
    tar xzf jasper-${JASPER_VERSION}.tar.gz && \
    cd jasper-${JASPER_VERSION} && \
    CFLAGS="-O2 -fPIC \
        -Wno-implicit-function-declaration \
        -Wno-incompatible-pointer-types \
        -Wno-implicit-int" \
    ./configure \
        --prefix=/dependencias/jasper && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/jasper*
```

O processo executado pelo Docker é:

```text id="q9c7fq"
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

## 2.2. Variáveis de ambiente

No seu `Dockerfile`, o Jasper é disponibilizado através das variáveis:

```dockerfile id="7ih4gk"
ENV JASPERINC=/dependencias/jasper/include
ENV JASPERLIB=/dependencias/jasper/lib
```

O caminho das bibliotecas também é adicionado ao `LD_LIBRARY_PATH`:

```dockerfile id="f6r4mg"
ENV LD_LIBRARY_PATH="/dependencias/jasper/lib:${LD_LIBRARY_PATH}"
```

Essas variáveis são importantes para o processo de compilação do WPS, pois permitem que o sistema encontre os headers e bibliotecas do Jasper.

---

## 2.3. Construção da imagem

Com o bloco do Jasper presente no `Dockerfile`:

```bash id="k9h6k2"
docker build -t mpas-jasper .
```

O Docker realizará automaticamente o download, compilação e instalação.

---

## 2.4. Verificação no container

Execute um shell dentro do container:

```bash id="g0w4dq"
docker run --rm -it mpas-jasper bash
```

Verifique os headers:

```bash id="7t9ywm"
ls /dependencias/jasper/include
```

Verifique as bibliotecas:

```bash id="9b7f7b"
ls /dependencias/jasper/lib
```

Verifique as variáveis:

```bash id="d4h1pv"
echo $JASPERINC
echo $JASPERLIB
```

Os resultados esperados são:

```text id="j2njf7"
/dependencias/jasper/include
/dependencias/jasper/lib
```

---

# 3. Relação com o WPS

No seu ambiente, o Jasper está relacionado principalmente ao **WPS**, e não diretamente ao núcleo do MPAS.

O WPS utiliza o `ungrib` para processar arquivos meteorológicos, incluindo dados GRIB2.

A relação simplificada é:

```text id="8s6r6w"
Dados meteorológicos
        │
        ▼
      GRIB2
        │
        ▼
       WPS
        │
        ▼
     ungrib
        │
        ▼
     Jasper
        │
        ▼
Dados processados
        │
        ▼
       MPAS
```

O Jasper fornece suporte ao processamento de dados JPEG-2000 presentes em determinados arquivos GRIB2.

---

# 4. Relação com o MPAS

O Jasper **não é uma dependência principal do sistema de I/O do MPAS**.

Sua função está relacionada ao fluxo de pré-processamento:

```text id="m4j3y5"
WPS
 │
 └── ungrib
       │
       └── Jasper
              │
              ▼
        Dados meteorológicos
              │
              ▼
             MPAS
```

---

# 5. Resumo

| Item                | Configuração                               |
| ------------------- | ------------------------------------------ |
| Biblioteca          | Jasper                                     |
| Versão              | `1.900.1`                                  |
| Linguagem           | C                                          |
| Diretório           | `/dependencias/jasper`                     |
| Headers             | `/dependencias/jasper/include`             |
| Bibliotecas         | `/dependencias/jasper/lib`                 |
| Build system        | Autotools (`configure`/`make`)             |
| Compilador          | GCC                                        |
| Otimização          | `-O2`                                      |
| Código PIC          | `-fPIC`                                    |
| Utilização          | WPS / `ungrib`                             |
| Formato relacionado | GRIB2 / JPEG-2000                          |
| Função no MPAS      | Suporte ao pré-processamento meteorológico |

O Jasper deve ser instalado **antes da compilação do WPS**, pois o `ungrib` pode depender de suas bibliotecas para processar determinados dados GRIB2. No seu `Dockerfile`, essa dependência é configurada através de `JASPERINC` e `JASPERLIB`.

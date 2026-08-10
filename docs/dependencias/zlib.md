# Instalação da zlib

## 1. Instalação sem Docker

A instalação manual consiste em baixar o código-fonte da zlib, compilá-lo e instalá-lo em um diretório definido pelo usuário.

### 1.1. Dependências

Em sistemas baseados em Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y wget tar build-essential
```

### 1.2. Download

Defina a versão da zlib:

```bash
export ZLIB_VERSION=1.3.2
```

Baixe o código-fonte:

```bash
wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
```

Extraia o arquivo:

```bash
tar xzf zlib-${ZLIB_VERSION}.tar.gz
```

Entre no diretório:

```bash
cd zlib-${ZLIB_VERSION}
```

### 1.3. Configuração

Para manter as dependências do MPAS organizadas, a zlib pode ser instalada em:

```text
/dependencias/zlib
```

Configure a compilação:

```bash
./configure --prefix=/dependencias/zlib
```

### 1.4. Compilação

Compile utilizando os processadores disponíveis:

```bash
make -j$(nproc)
```

### 1.5. Instalação

Instale a biblioteca:

```bash
make install
```

Após a instalação, os principais arquivos estarão em:

```text
/dependencias/zlib/
├── include/
│   └── zlib.h
└── lib/
    ├── libz.a
    └── libz.so
```

### 1.6. Verificação

Verifique o header:

```bash
ls /dependencias/zlib/include/zlib.h
```

Verifique as bibliotecas:

```bash
ls /dependencias/zlib/lib/libz*
```

Verifique a versão:

```bash
grep ZLIB_VERSION /dependencias/zlib/include/zlib.h
```

Para que outras bibliotecas do MPAS encontrem essa instalação, podem ser definidos:

```bash
export ZLIB_ROOT=/dependencias/zlib
export CPPFLAGS="-I${ZLIB_ROOT}/include"
export LDFLAGS="-L${ZLIB_ROOT}/lib"
export LD_LIBRARY_PATH="${ZLIB_ROOT}/lib:${LD_LIBRARY_PATH}"
```

---

## 2. Instalação com Docker

No ambiente Docker, a instalação da zlib pode ser automatizada diretamente no `Dockerfile`.

A versão é definida através de um argumento:

```dockerfile
ARG ZLIB_VERSION=1.3.2
```

O código-fonte é baixado, compilado e instalado em `/dependencias/zlib`:

```dockerfile
RUN cd /build && \
    wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar xzf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure --prefix=/dependencias/zlib && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/zlib*
```

Nesse processo:

1. `wget` baixa o código-fonte da zlib;
2. `tar` extrai o código-fonte;
3. `./configure` define `/dependencias/zlib` como diretório de instalação;
4. `make` realiza a compilação;
5. `make install` instala a biblioteca;
6. `rm` remove os arquivos temporários de compilação.

### 2.1. Disponibilização da biblioteca

Para que as demais dependências do MPAS encontrem a zlib dentro do container, o caminho da biblioteca pode ser adicionado ao `LD_LIBRARY_PATH`:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/zlib/lib:${LD_LIBRARY_PATH}"
```

Também pode ser definido um caminho para facilitar a configuração das bibliotecas dependentes:

```dockerfile
ENV ZLIB_ROOT=/dependencias/zlib
```

### 2.2. Construção da imagem

Com o `Dockerfile` configurado:

```bash
docker build -t mpas-zlib .
```

O processo de `docker build` executará automaticamente as etapas de download, compilação e instalação da zlib.

### 2.3. Verificação

Após construir a imagem:

```bash
docker run --rm -it mpas-zlib bash
```

Dentro do container:

```bash
ls /dependencias/zlib/include/zlib.h
```

e:

```bash
ls /dependencias/zlib/lib/libz*
```

A instalação estará disponível em:

```text
/dependencias/zlib
├── include/
│   └── zlib.h
└── lib/
    ├── libz.a
    └── libz.so
```

## 3. Comparação dos métodos

| Método              | Característica                                                |
| ------------------- | ------------------------------------------------------------- |
| Sem Docker          | Instalação diretamente no sistema ou em um diretório definido |
| Com Docker          | Instalação automatizada durante a construção da imagem        |
| Versão              | `1.3.2`                                                       |
| Diretório utilizado | `/dependencias/zlib`                                          |
| Compilador          | GCC                                                           |
| Build               | `make`                                                        |
| Instalação          | `make install`                                                |

Em ambos os métodos, o resultado é a mesma estrutura de instalação. A diferença está apenas no ambiente em que a compilação é executada.
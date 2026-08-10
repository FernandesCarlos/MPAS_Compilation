# Instalação do GKlib

## 1. Instalação sem Docker

O **GKlib** é uma biblioteca auxiliar desenvolvida pelo mesmo conjunto de ferramentas associado ao METIS. Ela fornece funções e estruturas utilizadas pelo METIS durante sua compilação e execução.

No ambiente do MPAS, o GKlib não é uma biblioteca de I/O. Sua função está relacionada à infraestrutura utilizada pelo **METIS para particionamento de grafos e decomposição do domínio**.

Neste ambiente, o GKlib será instalado em:

```text
/dependencias/metis
```

A relação entre as bibliotecas é:

```text
GKlib
  ↓
METIS
  ↓
Particionamento do domínio
  ↓
MPAS
```

### 1.1. Dependências

Em sistemas baseados em Ubuntu, instale as ferramentas necessárias:

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

### 1.2. Download

O código-fonte pode ser obtido diretamente do repositório:

```bash
cd /build

git clone --depth 1 \
    https://github.com/KarypisLab/GKlib.git
```

Entre no diretório:

```bash
cd GKlib
```

---

### 1.3. Configuração

No seu ambiente, o GKlib utiliza:

```text
/dependencias/metis
```

como diretório de instalação.

Configure:

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
| `cc=gcc`   | Define o compilador C               |
| `shared=1` | Habilita bibliotecas compartilhadas |

A opção:

```bash
shared=1
```

faz com que as bibliotecas compartilhadas sejam construídas, permitindo que o METIS e outras aplicações utilizem essas bibliotecas dinamicamente.

---

### 1.4. Compilação

Compile o GKlib:

```bash
make -j$(nproc)
```

O número de processos utilizados na compilação é determinado por:

```bash
$(nproc)
```

que retorna a quantidade de CPUs disponíveis no sistema.

---

### 1.5. Instalação

Instale:

```bash
make install
```

Os arquivos serão instalados em:

```text
/dependencias/metis
```

A estrutura resultante será semelhante a:

```text
/dependencias/metis/
├── include/
└── lib/
```

Os principais arquivos estarão em:

```text
/dependencias/metis/include
/dependencias/metis/lib
```

---

### 1.6. Configuração do ambiente

Adicione as bibliotecas ao caminho de execução:

```bash
export LD_LIBRARY_PATH="/dependencias/metis/lib:${LD_LIBRARY_PATH}"
```

Para facilitar a compilação do METIS e de outras aplicações:

```bash
export CPPFLAGS="-I/dependencias/metis/include"
export LDFLAGS="-L/dependencias/metis/lib"
```

---

### 1.7. Verificação

Verifique os headers:

```bash
ls /dependencias/metis/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/metis/lib
```

As bibliotecas compartilhadas do GKlib devem estar disponíveis no diretório:

```text
/dependencias/metis/lib
```

---

# 2. Instalação com Docker

No `Dockerfile`, o GKlib é compilado antes do METIS, pois o METIS depende dele.

O diretório de instalação utilizado é:

```text
/dependencias/metis
```

### 2.1. Compilação no Dockerfile

O bloco utilizado no seu `Dockerfile` é:

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

O processo executa:

```text
Clone
  ↓
Configuração
  ↓
Compilação
  ↓
Instalação
```

O código-fonte é obtido através de:

```bash
git clone --depth 1 https://github.com/KarypisLab/GKlib.git
```

O `--depth 1` realiza um clone superficial, obtendo somente o histórico necessário para a compilação e reduzindo o tamanho dos arquivos baixados.

---

## 2.2. Configuração utilizada

A configuração do seu `Dockerfile` é:

```bash
make config \
    prefix=/dependencias/metis \
    cc=gcc \
    shared=1
```

O resultado é instalado no mesmo prefixo utilizado posteriormente pelo METIS.

Isso permite que o METIS seja configurado com:

```bash
gklib_path=/dependencias/metis
```

Assim, a relação entre os dois componentes é:

```text
GKlib
  │
  └── /dependencias/metis
          │
          ▼
        METIS
          │
          └── gklib_path=/dependencias/metis
```

---

## 2.3. Variáveis de ambiente

No seu `Dockerfile`, as bibliotecas instaladas pelo GKlib ficam disponíveis através do:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/metis/lib:${LD_LIBRARY_PATH}"
```

Dessa forma, o sistema consegue localizar as bibliotecas compartilhadas durante a execução.

---

## 2.4. Construção da imagem

Com o GKlib presente no `Dockerfile`:

```bash
docker build -t mpas-gklib .
```

O Docker executará automaticamente a compilação e instalação.

---

## 2.5. Verificação no container

Execute um shell dentro do container:

```bash
docker run --rm -it mpas-gklib bash
```

Verifique os headers:

```bash
ls /dependencias/metis/include
```

Verifique as bibliotecas:

```bash
ls /dependencias/metis/lib
```

---

# 3. Relação com o METIS

O GKlib é utilizado diretamente pelo METIS durante sua construção.

A ordem de instalação deve ser:

```text
GKlib
  ↓
METIS
```

No seu ambiente, os dois utilizam o mesmo prefixo:

```text
/dependencias/metis
```

Depois que o GKlib é instalado, o METIS é configurado indicando explicitamente sua localização:

```bash
make config \
    shared=1 \
    cc=gcc \
    prefix=/dependencias/metis \
    gklib_path=/dependencias/metis
```

Portanto, o GKlib não é uma dependência independente do sistema de I/O do MPAS. Ele é uma **dependência de construção e suporte do METIS**, que por sua vez é utilizado para o particionamento do domínio.

---

# 4. Relação com o MPAS

A relação pode ser representada como:

```text
                    MPAS
                      │
                      ▼
              Particionamento
                      │
                      ▼
                    METIS
                      │
                      ▼
                    GKlib
```

O GKlib fornece funcionalidades auxiliares para o METIS. O METIS realiza o particionamento do grafo associado à malha, permitindo distribuir o domínio computacional entre processos MPI.

Assim, o GKlib participa **indiretamente** da preparação do ambiente de execução do MPAS.

---

# 5. Resumo

| Item                       | Configuração                         |
| -------------------------- | ------------------------------------ |
| Biblioteca                 | GKlib                                |
| Compilador                 | GCC                                  |
| Linguagem                  | C                                    |
| Bibliotecas compartilhadas | Habilitadas                          |
| Diretório                  | `/dependencias/metis`                |
| Build                      | `make`                               |
| Configuração               | `make config`                        |
| Instalação                 | `make install`                       |
| Dependente direto          | METIS                                |
| Função no MPAS             | Suporte ao particionamento via METIS |
| Categoria                  | Particionamento, não I/O             |

A instalação do GKlib deve ocorrer **antes do METIS**. No seu `Dockerfile`, essa ordem já está correta: primeiro o GKlib é compilado e instalado em `/dependencias/metis`, depois o METIS é configurado utilizando `gklib_path=/dependencias/metis`.

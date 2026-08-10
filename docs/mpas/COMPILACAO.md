# Compilação do MPAS

## 1. Pré-requisitos

Antes de iniciar a compilação do MPAS, as dependências necessárias devem estar instaladas e configuradas.

O ambiente utilizado neste projeto possui:

| Dependência    | Diretório               |
| -------------- | ----------------------- |
| NetCDF-C       | `/dependencias/netcdf`  |
| NetCDF-Fortran | `/dependencias/netcdf`  |
| PnetCDF        | `/dependencias/pnetcdf` |
| PIO            | `/dependencias/pio`     |
| METIS          | `/dependencias/metis`   |
| HDF5           | `/dependencias/hdf5`    |
| zlib           | `/dependencias/zlib`    |

Também são necessários:

* GCC;
* GFortran;
* MPI;
* GNU Make.

Verifique os compiladores:

```bash
gcc --version
gfortran --version
mpicc --version
mpif90 --version
```

Verifique o MPI:

```bash
mpirun --version
```

---

# 2. Configuração das variáveis de ambiente

Antes de compilar o MPAS, configure as variáveis utilizadas pelas dependências.

```bash
export NETCDF=/dependencias/netcdf
export PNETCDF=/dependencias/pnetcdf
export PIO=/dependencias/pio
```

Adicione os executáveis ao `PATH`:

```bash
export PATH="/dependencias/netcdf/bin:/dependencias/pio/bin:/dependencias/pnetcdf/bin:/dependencias/metis/bin:${PATH}"
```

Configure o caminho das bibliotecas:

```bash
export LD_LIBRARY_PATH="/dependencias/hdf5/lib:/dependencias/zlib/lib:/dependencias/netcdf/lib:/dependencias/pio/lib:/dependencias/pnetcdf/lib:/dependencias/metis/lib:${LD_LIBRARY_PATH}"
```

Essas variáveis permitem que o compilador e o linker localizem os headers, bibliotecas e executáveis necessários durante a compilação.

Verifique o NetCDF:

```bash
nc-config --version
```

Verifique o NetCDF-Fortran:

```bash
nf-config --version
```

Verifique o PIO:

```bash
ls ${PIO}
```

---

# 3. Obtenção do código-fonte

Neste projeto, a versão utilizada é:

```text
MPAS v8.4.1
```

Clone o repositório:

```bash
git clone --branch v8.4.1 --depth 1 \
    https://github.com/MPAS-Dev/MPAS-Model.git
```

Entre no diretório:

```bash
cd MPAS-Model
```

A estrutura do código contém diferentes componentes do modelo, chamados de **cores**.

Para este projeto, será utilizado o core:

```text
atmosphere
```

---

# 4. Compilação do MPAS-Atmosphere

A compilação do MPAS é realizada através do `Makefile` fornecido pelo projeto.

Para compilar o core `atmosphere` utilizando o PIO2:

```bash
make gnu CORE=atmosphere USE_PIO2=true
```

Essa configuração corresponde ao ambiente utilizado no `Dockerfile`:

```bash
make gnu CORE=atmosphere USE_PIO2=true
```

Os principais parâmetros são:

| Parâmetro         | Função                     |
| ----------------- | -------------------------- |
| `make`            | Sistema de compilação      |
| `gnu`             | Utiliza a toolchain GNU    |
| `CORE=atmosphere` | Compila o core atmosférico |
| `USE_PIO2=true`   | Habilita o PIO2            |

---

# 5. Compilação paralela

A compilação pode ser acelerada utilizando múltiplos processos:

```bash
make -j$(nproc) gnu CORE=atmosphere USE_PIO2=true
```

A opção:

```text
-j$(nproc)
```

permite executar múltiplas tarefas de compilação simultaneamente, utilizando os processadores disponíveis.

Em ambientes com muitos núcleos, isso pode reduzir significativamente o tempo de compilação.

---

# 6. Problemas relacionados às bibliotecas

Um erro comum durante a compilação ocorre quando o compilador não encontra os headers ou bibliotecas do NetCDF, PIO ou PnetCDF.

Verifique primeiro:

```bash
echo $NETCDF
echo $PNETCDF
echo $PIO
```

Os resultados devem apontar para:

```text
/dependencias/netcdf
/dependencias/pnetcdf
/dependencias/pio
```

Verifique também:

```bash
echo $LD_LIBRARY_PATH
```

Os diretórios das bibliotecas devem estar presentes.


---

# 7. Compilação com Docker

No ambiente Docker, as dependências já são instaladas durante a construção da imagem.

As variáveis de ambiente são configuradas no `Dockerfile`:

```dockerfile
ENV NETCDF=/dependencias/netcdf
ENV PNETCDF=/dependencias/pnetcdf
ENV PIO=/dependencias/pio
```

O `PATH` também é configurado:

```dockerfile
ENV PATH="/dependencias/netcdf/bin:/dependencias/pio/bin:/dependencias/pnetcdf/bin:/dependencias/metis/bin:${PATH}"
```

E as bibliotecas:

```dockerfile
ENV LD_LIBRARY_PATH="/dependencias/hdf5/lib:/dependencias/zlib/lib:/dependencias/netcdf/lib:/dependencias/pio/lib:/dependencias/jasper/lib:/dependencias/pnetcdf/lib:/dependencias/metis/lib"
```

Dessa forma, o ambiente necessário para compilar o MPAS já está disponível dentro do container.

---

## 7.1. Compilação manual dentro do container

Entre no container:

```bash
docker run --rm -it mpas bash
```

Entre no diretório do MPAS:

```bash
cd /mpas/MPAS-Model
```

Execute:

```bash
make gnu CORE=atmosphere USE_PIO2=true
```

Para uma compilação paralela:

```bash
make -j$(nproc) gnu CORE=atmosphere USE_PIO2=true
```

---

# 8. Relação entre as dependências e a compilação

O MPAS utiliza diferentes bibliotecas durante a compilação e execução.

A arquitetura geral do ambiente é:

```text
                    MPAS
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
         PIO        METIS        WPS
          │           │           │
     ┌────┴────┐      │         Jasper
     │         │      │
     ▼         ▼      ▼
 NetCDF    PnetCDF  Particionamento
     │
     ▼
    HDF5
     │
     ▼
    zlib
```

O **PIO** é responsável pela camada de I/O paralelo.

O **NetCDF** e o **PnetCDF** fornecem mecanismos de acesso aos dados.

O **HDF5** e o **zlib** dão suporte ao backend utilizado pelo NetCDF-4.

O **METIS/GKlib** estão relacionados ao particionamento do domínio.

O **Jasper/WPS** está relacionado ao pré-processamento dos dados meteorológicos.

---

# 9. Resumo

Para o ambiente deste projeto, a compilação principal do MPAS-Atmosphere é:

```bash
make gnu CORE=atmosphere USE_PIO2=true
```

Ou, utilizando compilação paralela:

```bash
make -j$(nproc) gnu CORE=atmosphere USE_PIO2=true
```

A ordem geral do ambiente é:

```text
1. zlib
2. HDF5
3. NetCDF-C
4. NetCDF-Fortran
5. PnetCDF
6. PIO
7. GKlib
8. METIS
9. Jasper
10. WPS
11. MPAS
```

Após uma compilação bem-sucedida, o ambiente está preparado para a etapa seguinte: **configuração dos dados, preparação do domínio e execução do MPAS**.

FROM ubuntu:24.04 AS mpas-dev

# ==============================================================================
# VERSÕES
# ==============================================================================
# As versões ficam centralizadas aqui para facilitar a atualização das
# bibliotecas sem precisar procurar números de versão pelo Dockerfile inteiro.

ARG ZLIB_VERSION=1.3.2
ARG HDF5_VERSION=1.14.6
ARG NETCDF_C_VERSION=4.9.3
ARG NETCDF_FORTRAN_VERSION=4.6.2
ARG PNETCDF_VERSION=1.12.3
ARG PIO_VERSION=2.6.8
ARG METIS_VERSION=5.2.1
ARG WPS_VERSION=v4.5
ARG MPAS_VERSION=v8.4.1
ARG CDSAPI_VERSION=0.7.7

# Evita perguntas interativas do apt durante a construção da imagem.
ENV DEBIAN_FRONTEND=noninteractive


# ==============================================================================
# PACOTES DO SISTEMA
# ==============================================================================
# Aqui são instalados os compiladores e ferramentas usados para construir
# todas as bibliotecas do MPAS. MPICH fornece mpicc, mpicxx e mpif90.

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        gfortran \
        cmake \
        git \
        wget \
        curl \
        ca-certificates \
        tar \
        file \
        m4 \
        perl \
        pkg-config \
        gawk \
        mpich \
        libmpich-dev \
        python3 \
        python3-pip \
        python3-venv \
        csh \
        libpng-dev \
        libxml2-dev \
        nano && \
    rm -rf /var/lib/apt/lists/*


# ==============================================================================
# DIRETÓRIOS
# ==============================================================================
# /build é usado apenas durante a compilação das bibliotecas.
# /dependencias recebe as bibliotecas instaladas.
# /mpas contém o código e os arquivos de execução do MPAS.
# /dados recebe dados externos montados por volume.
# /workspace contém scripts auxiliares do projeto.

RUN mkdir -p \
        /build \
        /dependencias \
        /mpas \
        /mpas/run \
        /dados/era5 \
        /workspace/scripts


# ==============================================================================
# ZLIB
# ==============================================================================
# A zlib fornece compressão usada pelo HDF5 e pelo NetCDF.

RUN cd /build && \
    git clone \
        --depth 1 \
        --branch v${ZLIB_VERSION} \
        https://github.com/madler/zlib.git \
        zlib-${ZLIB_VERSION} && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure \
        --prefix=/dependencias/zlib && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf /build/zlib-${ZLIB_VERSION}


# ==============================================================================
# HDF5
# ==============================================================================
# O HDF5 é compilado com MPI porque o NetCDF-4 usado pelo MPAS precisa de
# suporte a acesso paralelo.

RUN cd /build && \
    wget \
        https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/hdf5-${HDF5_VERSION}.tar.gz \
        -O hdf5-${HDF5_VERSION}.tar.gz && \
    tar xzf hdf5-${HDF5_VERSION}.tar.gz && \
    cd hdf5-${HDF5_VERSION} && \
    CC=mpicc \
    FC=mpif90 \
    CPPFLAGS="-I/dependencias/zlib/include" \
    LDFLAGS="-L/dependencias/zlib/lib" \
    ./configure \
        --prefix=/dependencias/hdf5 \
        --enable-parallel \
        --enable-fortran \
        --with-zlib=/dependencias/zlib && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/hdf5-${HDF5_VERSION} \
        /build/hdf5-${HDF5_VERSION}.tar.gz


# ==============================================================================
# NETCDF-C
# ==============================================================================
# O NetCDF-C é compilado usando o HDF5 e a zlib instalados anteriormente.
# O suporte DAP é desativado porque não é necessário para a execução do MPAS.

RUN cd /build && \
    wget \
        https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_C_VERSION}/netcdf-c-${NETCDF_C_VERSION}.tar.gz \
        -O netcdf-c-${NETCDF_C_VERSION}.tar.gz && \
    tar xzf netcdf-c-${NETCDF_C_VERSION}.tar.gz && \
    cd netcdf-c-${NETCDF_C_VERSION} && \
    CC=mpicc \
    CPPFLAGS="-I/dependencias/hdf5/include -I/dependencias/zlib/include" \
    LDFLAGS="-L/dependencias/hdf5/lib -L/dependencias/zlib/lib" \
    ./configure \
        --prefix=/dependencias/netcdf \
        --enable-netcdf4 \
        --disable-dap \
        --disable-libxml2 && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/netcdf-c-${NETCDF_C_VERSION} \
        /build/netcdf-c-${NETCDF_C_VERSION}.tar.gz


# ==============================================================================
# NETCDF-FORTRAN
# ==============================================================================
# O MPAS é escrito principalmente em Fortran, por isso além do NetCDF-C também
# é necessária a interface Fortran do NetCDF.

RUN cd /build && \
    wget \
        https://downloads.unidata.ucar.edu/netcdf-fortran/${NETCDF_FORTRAN_VERSION}/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz \
        -O netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz && \
    tar xzf netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz && \
    cd netcdf-fortran-${NETCDF_FORTRAN_VERSION} && \
    CC=mpicc \
    FC=mpif90 \
    CPPFLAGS="-I/dependencias/netcdf/include" \
    LDFLAGS="-L/dependencias/netcdf/lib" \
    ./configure \
        --prefix=/dependencias/netcdf && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/netcdf-fortran-${NETCDF_FORTRAN_VERSION} \
        /build/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz


# ==============================================================================
# PARALLEL-NETCDF
# ==============================================================================
# O Parallel-NetCDF permite operações paralelas em arquivos NetCDF clássicos
# e é uma das bibliotecas de I/O utilizadas pelo MPAS.

RUN cd /build && \
    wget \
        https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz \
        -O pnetcdf-${PNETCDF_VERSION}.tar.gz && \
    tar xzf pnetcdf-${PNETCDF_VERSION}.tar.gz && \
    cd pnetcdf-${PNETCDF_VERSION} && \
    CC=mpicc \
    CXX=mpicxx \
    FC=mpif90 \
    ./configure \
        --prefix=/dependencias/pnetcdf \
        --enable-fortran && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/pnetcdf-${PNETCDF_VERSION} \
        /build/pnetcdf-${PNETCDF_VERSION}.tar.gz


# ==============================================================================
# PIO
# ==============================================================================
# O ParallelIO organiza o acesso paralelo aos arquivos de entrada e saída.
# Ele é compilado apontando explicitamente para NetCDF e Parallel-NetCDF.

RUN cd /build && \
    wget \
        https://github.com/NCAR/ParallelIO/archive/refs/tags/pio$(echo ${PIO_VERSION} | tr . _).tar.gz \
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
        -DCMAKE_CXX_COMPILER=mpicxx \
        -DCMAKE_Fortran_COMPILER=mpif90 && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/ParallelIO-pio$(echo ${PIO_VERSION} | tr . _) \
        /build/pio-${PIO_VERSION}.tar.gz


# ==============================================================================
# GKLIB E METIS
# ==============================================================================
# GKlib é uma dependência do METIS.
# O METIS fornece o gpmetis, usado para particionar o grafo da malha do MPAS.

RUN cd /build && \
    git clone \
        --depth 1 \
        https://github.com/KarypisLab/GKlib.git && \
    cd GKlib && \
    make config \
        prefix=/dependencias/metis \
        cc=gcc \
        shared=1 && \
    make -j"$(nproc)" && \
    make install && \
    cd /build && \
    git clone \
        --depth 1 \
        --branch v${METIS_VERSION} \
        https://github.com/KarypisLab/METIS.git && \
    cd METIS && \
    make config \
        prefix=/dependencias/metis \
        gklib_path=/dependencias/metis \
        cc=gcc \
        shared=1 && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/GKlib \
        /build/METIS


# ==============================================================================
# AMBIENTE DAS BIBLIOTECAS
# ==============================================================================
# Estas variáveis informam ao sistema de build do MPAS onde estão NetCDF,
# Parallel-NetCDF e PIO.
#
# PATH permite executar programas como nc-config, nf-config e gpmetis.
# LD_LIBRARY_PATH permite que o Linux encontre as bibliotecas compartilhadas
# durante a execução dos programas.

ENV NETCDF=/dependencias/netcdf
ENV PNETCDF=/dependencias/pnetcdf
ENV PIO=/dependencias/pio

ENV PATH="/opt/cdsapi/bin:/dependencias/netcdf/bin:/dependencias/pnetcdf/bin:/dependencias/pio/bin:/dependencias/metis/bin:${PATH}"

ENV LD_LIBRARY_PATH="/dependencias/zlib/lib:/dependencias/hdf5/lib:/dependencias/netcdf/lib:/dependencias/pnetcdf/lib:/dependencias/pio/lib:/dependencias/metis/lib:/usr/lib/x86_64-linux-gnu"


# ==============================================================================
# CDSAPI
# ==============================================================================
# O cliente do Climate Data Store fica em um ambiente virtual separado.
# O arquivo .cdsapirc não é copiado para a imagem; ele deve ser montado no
# container quando for necessário baixar dados ERA5.

RUN python3 -m venv /opt/cdsapi && \
    /opt/cdsapi/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/cdsapi/bin/pip install --no-cache-dir cdsapi==${CDSAPI_VERSION}


# ==============================================================================
# WPS
# ==============================================================================
# O código do WPS é baixado, mas não é compilado durante o docker build.
# Dentro do container será usado somente o ungrib, responsável por transformar
# os arquivos GRIB do ERA5 no formato intermediário usado pelo MPAS.

RUN git clone \
        --depth 1 \
        --branch ${WPS_VERSION} \
        https://github.com/wrf-model/WPS.git \
        /build/WPS


# ==============================================================================
# MPAS
# ==============================================================================
# O código-fonte do MPAS fica disponível no container para que os cores sejam
# compilados manualmente. Dessa forma é possível estudar e alterar as opções de
# compilação sem reconstruir toda a cadeia de dependências.

RUN git clone \
        --depth 1 \
        --branch ${MPAS_VERSION} \
        https://github.com/MPAS-Dev/MPAS-Model.git \
        /mpas/MPAS-Model


# ==============================================================================
# SCRIPTS DO PROJETO
# ==============================================================================
# Os scripts locais ficam separados do código-fonte do MPAS e do WPS.

COPY scripts/ /workspace/scripts/

RUN chmod -R a+rX /workspace/scripts


# ==============================================================================
# DIRETÓRIO INICIAL
# ==============================================================================
# Ao abrir o container, o terminal começa em /mpas.
# Dados ERA5, malhas e saídas devem ser montados externamente em /dados e
# /mpas/run, em vez de serem adicionados permanentemente à imagem.

WORKDIR /mpas

CMD ["/bin/bash"]
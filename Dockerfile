FROM ubuntu:24.04 AS mpas-dev

# ==============================================================================
# VERSÕES
# ==============================================================================
# As versões ficam centralizadas para facilitar atualização e auditoria.

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

ENV DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# PACOTES DO SISTEMA
# ==============================================================================
# MPICH fornece mpicc, mpicxx e mpif90. python3-netcdf4 é usado pelos
# validadores de saída do caso reproduzível.

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
        python3-netcdf4 \
        csh \
        libpng-dev \
        libxml2-dev \
        nano && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# DIRETÓRIOS
# ==============================================================================

RUN mkdir -p \
        /build \
        /dependencias \
        /mpas \
        /mpas/run \
        /dados/era5 \
        /workspace/scripts \
        /workspace/cases \
        /workspace/tests \
        /workspace/data \
        /workspace/work

# ==============================================================================
# ZLIB
# ==============================================================================

RUN cd /build && \
    git clone \
        --depth 1 \
        --branch v${ZLIB_VERSION} \
        https://github.com/madler/zlib.git \
        zlib-${ZLIB_VERSION} && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure --prefix=/dependencias/zlib && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf /build/zlib-${ZLIB_VERSION}

# ==============================================================================
# HDF5 PARALELO
# ==============================================================================

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
    ./configure --prefix=/dependencias/netcdf && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf \
        /build/netcdf-fortran-${NETCDF_FORTRAN_VERSION} \
        /build/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz

# ==============================================================================
# PARALLEL-NETCDF
# ==============================================================================

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

RUN cd /build && \
    git clone --depth 1 https://github.com/KarypisLab/GKlib.git && \
    cd GKlib && \
    make config prefix=/dependencias/metis cc=gcc shared=1 && \
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
    rm -rf /build/GKlib /build/METIS

# ==============================================================================
# AMBIENTE DAS BIBLIOTECAS
# ==============================================================================

ENV NETCDF=/dependencias/netcdf
ENV PNETCDF=/dependencias/pnetcdf
ENV PIO=/dependencias/pio
ENV PATH="/opt/cdsapi/bin:/dependencias/netcdf/bin:/dependencias/pnetcdf/bin:/dependencias/pio/bin:/dependencias/metis/bin:${PATH}"
ENV LD_LIBRARY_PATH="/dependencias/zlib/lib:/dependencias/hdf5/lib:/dependencias/netcdf/lib:/dependencias/pnetcdf/lib:/dependencias/pio/lib:/dependencias/metis/lib:/usr/lib/x86_64-linux-gnu"

# ==============================================================================
# CDSAPI E VALIDAÇÃO PYTHON
# ==============================================================================
# O venv vê os pacotes do sistema para reutilizar python3-netcdf4 sem manter
# uma segunda cópia da stack NetCDF. A credencial ~/.cdsapirc nunca é copiada.

RUN python3 -m venv --system-site-packages /opt/cdsapi && \
    /opt/cdsapi/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/cdsapi/bin/pip install --no-cache-dir cdsapi==${CDSAPI_VERSION}

# ==============================================================================
# WPS
# ==============================================================================
# O source é mantido para fins didáticos. scripts/prepare/build_tools.sh usa
# ./configure --nowrf --build-grib2-libs e compila apenas ungrib quando preciso.

RUN git clone \
        --depth 1 \
        --branch ${WPS_VERSION} \
        https://github.com/wrf-model/WPS.git \
        /build/WPS

# ==============================================================================
# MPAS
# ==============================================================================
# Os cores continuam compiláveis manualmente; a automação apenas oferece um
# caminho opcional e reproduzível para init_atmosphere e atmosphere.

RUN git clone \
        --depth 1 \
        --branch ${MPAS_VERSION} \
        https://github.com/MPAS-Dev/MPAS-Model.git \
        /mpas/MPAS-Model

# ==============================================================================
# ARTEFATOS VERSIONADOS DO PROJETO
# ==============================================================================

COPY scripts/ /workspace/scripts/
COPY cases/ /workspace/cases/
COPY tests/ /workspace/tests/

RUN find /workspace/scripts /workspace/tests \
        -type f -name '*.sh' -exec chmod 0755 {} + && \
    chmod -R a+rX /workspace/cases

# Mantém o diretório inicial histórico; para o pipeline execute `cd /workspace`.
WORKDIR /mpas

CMD ["/bin/bash"]

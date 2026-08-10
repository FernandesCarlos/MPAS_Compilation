
FROM ubuntu:24.04

# ==============================================================================
# 1. VERSÕES
# ==============================================================================
ARG ZLIB_VERSION=1.3.2
ARG HDF5_VERSION=1.14.6
ARG NETCDF_C_VERSION=4.9.3
ARG NETCDF_FORTRAN_VERSION=4.6.2
ARG PNETCDF_VERSION=1.12.3
ARG PIO_VERSION=2.6.8
ARG JASPER_VERSION=1.900.1
ARG WPS_VERSION=v4.5
ARG METIS_VERSION=5.2.1
ARG MPAS_VERSION=v8.4.1

# ==============================================================================
# 2. PACOTES DO SISTEMA
# ==============================================================================
RUN apt-get update && \
    apt-get install -y \
    wget curl git tar xz-utils ca-certificates file nano \
    build-essential gcc g++ gfortran make cmake \
    m4 perl autoconf automake libtool pkg-config \
    mpich libmpich-dev \
    python3 zlib1g-dev libpng-dev libxml2-dev csh && \
    rm -rf /var/lib/apt/lists/*

# Diretórios base
RUN mkdir -p /build /dependencias /mpas

# ==============================================================================
# 3. ZLIB
# ==============================================================================
RUN cd /build && \
    wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar xzf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure --prefix=/dependencias/zlib && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/zlib*

# ==============================================================================
# 4. HDF5
# ==============================================================================
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

# ==============================================================================
# 5. NETCDF-C
# ==============================================================================
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

# ==============================================================================
# 6. NETCDF-FORTRAN
# ==============================================================================
RUN cd /build && \
    wget https://downloads.unidata.ucar.edu/netcdf-fortran/${NETCDF_FORTRAN_VERSION}/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz && \
    tar xzf netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz && \
    cd netcdf-fortran-${NETCDF_FORTRAN_VERSION} && \
    CPPFLAGS="-I/dependencias/netcdf/include" \
    LDFLAGS="-L/dependencias/netcdf/lib" \
    CC=mpicc FC=mpif90 ./configure \
        --prefix=/dependencias/netcdf && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/netcdf-fortran*

# ==============================================================================
# 7. PNETCDF
# ==============================================================================
RUN cd /build && \
    wget https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz && \
    tar xzf pnetcdf-${PNETCDF_VERSION}.tar.gz && \
    cd pnetcdf-${PNETCDF_VERSION} && \
    CC=mpicc CXX=mpicxx FC=mpif90 ./configure \
        --prefix=/dependencias/pnetcdf \
        --enable-fortran && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/pnetcdf*

# ==============================================================================
# 8. PIO
# ==============================================================================
RUN cd /build && \
    wget https://github.com/NCAR/ParallelIO/archive/refs/tags/pio$(echo ${PIO_VERSION} | tr . _).tar.gz \
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
        -DCMAKE_Fortran_COMPILER=mpif90 && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/pio* /build/ParallelIO*

# ==============================================================================
# 9. METIS + GKLIB
# ==============================================================================
RUN cd /build && \
    git clone --depth 1 https://github.com/KarypisLab/GKlib.git && \
    cd GKlib && \
    make config prefix=/dependencias/metis cc=gcc shared=1 && \
    make -j$(nproc) && \
    make install && \
    cd /build && \
    git clone --branch v${METIS_VERSION} --depth 1 https://github.com/KarypisLab/METIS.git && \
    cd METIS && \
    make config \
        shared=1 \
        cc=gcc \
        prefix=/dependencias/metis \
        gklib_path=/dependencias/metis && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/GKlib /build/METIS

# ==============================================================================
# 10. JASPER (GRIB2 / WPS)
# ==============================================================================
RUN cd /build && \
    wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-${JASPER_VERSION}.tar.gz && \
    tar xzf jasper-${JASPER_VERSION}.tar.gz && \
    cd jasper-${JASPER_VERSION} && \
    CFLAGS="-O2 -fPIC -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-implicit-int" \
    ./configure --prefix=/dependencias/jasper && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/jasper*

# ==============================================================================
# 11. VARIÁVEIS DE AMBIENTE
# ==============================================================================
ENV NETCDF=/dependencias/netcdf
ENV PNETCDF=/dependencias/pnetcdf
ENV PIO=/dependencias/pio
ENV JASPERINC=/dependencias/jasper/include
ENV JASPERLIB=/dependencias/jasper/lib

ENV PATH="/dependencias/netcdf/bin:/dependencias/pio/bin:/dependencias/pnetcdf/bin:/dependencias/metis/bin:${PATH}"

ENV LD_LIBRARY_PATH="/dependencias/hdf5/lib:/dependencias/zlib/lib:/dependencias/netcdf/lib:/dependencias/pio/lib:/dependencias/jasper/lib:/dependencias/pnetcdf/lib:/dependencias/metis/lib"

# ==============================================================================
# 12. WPS (somente UNGRIB)
# ==============================================================================
RUN cd /build && \
    git clone --branch ${WPS_VERSION} --depth 1 https://github.com/wrf-model/WPS.git && \
    cd WPS && \
    printf "1\n" | ./configure --nowrf && \
    ./compile ungrib && \
    test -x ungrib.exe && \
    file ungrib.exe && \
    mkdir -p /mpas/wps && \
    cp ungrib.exe /mpas/wps/ && \
    cp link_grib.csh /mpas/wps/ && \
    cp ungrib/Variable_Tables/Vtable.ERA-interim.pl /mpas/wps/ && \
    rm -rf /build/WPS

# ==============================================================================
# 13. MPAS
# ==============================================================================
WORKDIR /dados/era5

# Descomente para compilar automaticamente o MPAS
# RUN git clone --branch ${MPAS_VERSION} --depth 1 \
#     https://github.com/MPAS-Dev/MPAS-Model.git /mpas/MPAS-Model
#
# WORKDIR /mpas/MPAS-Model
#
# RUN make gnu CORE=atmosphere USE_PIO2=true


COPY dados-era5 /dados/era5

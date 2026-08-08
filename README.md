# MPAS Compilation

Ambiente Docker para compilação e execução do [MPAS](https://mpas-dev.github.io/) com suas principais dependências, incluindo bibliotecas de I/O, MPI, WPS e ferramentas auxiliares.

## Objetivo

Este projeto documenta e automatiza a construção de um ambiente para compilação do MPAS utilizando Docker, permitindo reproduzir o ambiente de compilação de forma consistente.

## Principais componentes

* MPAS v8.4.1
* WPS v4.5
* MPICH
* NetCDF-C
* NetCDF-Fortran
* PnetCDF
* PIO
* HDF5
* zlib
* METIS

## Estrutura

```text
├── Dockerfile
├── README.md
├── COMPILATION.md
├── baixar_ERA5.py
└── docs/
    ├── io-libraries/
    ├── mpi-libraries/
    └── mpas-core/
```

## Início rápido

```bash
docker build -t mpas-compilation .
docker run -it mpas-compilation
```

Para conhecer o processo completo de compilação, consulte:

* [COMPILATION.md](COMPILATION.md)
* [Documentação das bibliotecas](docs/)
* [Download dos dados ERA5](baixar_era5.py)

## Dados ERA5

O arquivo `baixar_era5.py` utiliza a API do Copernicus Climate Data Store (CDS) para realizar o download dos dados ERA5 necessários ao processamento.

Consulte a documentação do script antes de executar o download.
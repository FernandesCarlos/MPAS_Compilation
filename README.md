# MPAS — Ambiente de Compilação

Este projeto contém a configuração do ambiente necessário para **compilação e execução do MPAS-Atmosphere**, incluindo suas dependências e ferramentas de pré-processamento.

O ambiente pode ser configurado de duas formas:

* **Docker**, utilizando o `Dockerfile`;
* **Instalação manual**, compilando as dependências diretamente no sistema.

## Estrutura

```text
.
├── Dockerfile
├── README.md
├── dados-era5/
└── docs/
    ├── dependencias/
    ├── particionamento/
    ├── wps/
    └── mpas/
```

## Componentes

O ambiente é composto principalmente por:

* **Bibliotecas de I/O:** zlib, HDF5, NetCDF-C, NetCDF-Fortran, PnetCDF e PIO;
* **Particionamento:** GKlib e METIS;
* **Pré-processamento:** WPS, `ungrib` e Jasper;
* **Modelo:** MPAS-Atmosphere.

## Docker

Para construir a imagem:

```bash
docker build -t mpas .
```

Para iniciar o container:

```bash
docker run --rm -it mpas bash
```

A partir do container, as etapas de compilação e execução podem ser realizadas conforme a documentação.

## Compilação do MPAS

Após preparar o ambiente e acessar o código-fonte do MPAS:

```bash
make -j$(nproc) gnu CORE=atmosphere USE_PIO2=true
```

## Documentação

A documentação detalhada está organizada por componente:

* [`docs/dependencias/`](docs/dependencias/) — bibliotecas de I/O;
* [`docs/particionamento/`](docs/particionamento/) — GKlib e METIS;
* [`docs/wps/`](docs/wps/) — WPS, `ungrib` e Jasper;
* [`docs/mpas/`](docs/mpas/) — instalação, compilação e execução do MPAS.

## Versões principais

| Componente     | Versão  |
| -------------- | ------- |
| Ubuntu         | 24.04   |
| MPAS           | v8.4.1  |
| WPS            | v4.5    |
| zlib           | 1.3.2   |
| HDF5           | 1.14.6  |
| NetCDF-C       | 4.9.3   |
| NetCDF-Fortran | 4.6.2   |
| PnetCDF        | 1.12.3  |
| PIO            | 2.6.8   |
| METIS          | 5.2.1   |
| Jasper         | 1.900.1 |

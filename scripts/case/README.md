# Caso global de 240 km: uma etapa por arquivo

Este caso usa a malha global `x1.10242`, campos estáticos preparados pelo NCAR,
ERA5 no horário inicial e uma simulação curta sem atualização de SST. Execute os
scripts dentro do contêiner, em ordem. Cada etapa pode ser reexecutada sozinha.

## Parâmetros

Edite `scripts/case/caso.env` na cópia do repositório no computador; os scripts são
montados como somente leitura em `/workspace/scripts` dentro do contêiner.
Data, duração, passo de tempo, níveis do modelo, intervalos de saída e número de
processos estão nesse arquivo. Os demais parâmetros estão nos auxiliares Python,
especialmente `configure_case.py` e `download_era5.py`.

As variáveis exportadas no terminal têm prioridade sobre os valores de caso.env.
Pode usar uma cópia com outros parâmetros definindo `CASE_CONFIG=/caminho/caso.env`.
Para outra data, use também outro RUN_DIR para separar arquivos de inicialização
e resultados de simulações anteriores.

| Arquivo | Responsabilidade |
| --- | --- |
| `00_compilar.sh` | Compila os dois cores e copia executáveis, configurações e tabelas |
| `01_baixar_malha.sh` | Baixa malha e static.nc preparados e particiona para NP |
| `02_baixar_era5.sh` | Baixa dados globais de pressão, superfície e solo para START_TIME |
| `03_converter_era5.sh` | Converte os GRIB com ungrib para o intermediário ERA5 |
| `04_configurar_init.sh` | Ajusta namelist e streams da inicialização meteorológica |
| `05_gerar_init.sh` | Executa init_atmosphere_model para gerar init.nc |
| `06_configurar_atmosfera.sh` | Ajusta namelist e streams da atmosfera |
| `07_executar.sh` | Executa atmosphere_model |

## Pré-requisitos

O ambiente MPAS deve estar construído. No computador:

```bash
bash scripts/docker_mpas.sh build
bash scripts/docker_mpas.sh shell
```

O download depende de uma conta CDS, aceite das condições dos datasets e
credenciais válidas. Se sua credencial está em ~/.cdsapirc no computador, em
outro terminal do computador copie-a para o contêiner:

```bash
docker cp "$HOME/.cdsapirc" mpas-container:/root/.cdsapirc
```

O script 03 exige WPS/ungrib compilado; o Dockerfile atual não o compila. Defina
WPS_DIR se sua instalação estiver em outro caminho, por exemplo /mpas/wps.
Defina WPS_VTABLE como o caminho absoluto da tabela compatível com os GRIB.
Para dados ERA5 em níveis de pressão GRIB1, confira a tabela
`/build/WPS/ungrib/Variable_Tables/Vtable.ERA-interim.pl`; GRIB2 exige uma tabela
com os códigos GRIB2 correspondentes. O script não escolhe uma tabela sem essa
configuração. Confirme os códigos e os campos usando g1print/g2print e
rd_intermediate do WPS.

## Execução dentro do contêiner

```bash
bash /workspace/scripts/case/00_compilar.sh
bash /workspace/scripts/case/01_baixar_malha.sh
bash /workspace/scripts/case/02_baixar_era5.sh
bash /workspace/scripts/case/03_converter_era5.sh
bash /workspace/scripts/case/04_configurar_init.sh
bash /workspace/scripts/case/05_gerar_init.sh
bash /workspace/scripts/case/06_configurar_atmosfera.sh
bash /workspace/scripts/case/07_executar.sh
```

O script 01 usa o static.nc pronto: não é preciso executar a interpolação
geográfica para esse caso. Para outra malha ou outros dados de superfície, adapte
a aquisição e use o modo `static` de mpas.sh conforme o guia de execução.

Os scripts 04 e 06 alteram somente as opções do caso e atributos necessários
dos streams; os demais parâmetros e streams são mantidos. Antes da escrita,
fazem backups com sufixo `.bak.<timestamp>`. Opções Fortran devem estar uma por
linha nos arquivos gerados pela compilação. Ao reexecutar a configuração, os
valores definidos pelo caso são reaplicados; edições manuais nessas mesmas opções
serão substituídas, com backup.

Os arquivos ERA5 ficam em `/dados/era5/YYYY-MM-DD_HH/`. Downloads já existentes e
não vazios são preservados. Se alterar a lista de variáveis, mova os GRIB antigos
para outra pasta antes de baixar novamente: a existência não comprova conteúdo.
Downloads parciais usam a extensão `.download` e não são tratados como concluídos.

Este caso é global e de partida fria; não prepara limites laterais nem SST para
atualização durante simulações prolongadas. Passar nas verificações não comprova
integridade dos dados ou estabilidade numérica. As ferramentas científicas e os
downloads precisam ser testados no seu ambiente; os testes locais verificam a
lógica dos scripts e usam stubs para ferramentas externas.

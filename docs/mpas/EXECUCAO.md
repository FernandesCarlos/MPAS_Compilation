# Executar MPAS com os scripts

Os scripts automatizam o ambiente Docker, a compilação dos dois cores, o
particionamento e o lançamento MPI. Eles não baixam a malha nem dados geográficos,
não compilam o WPS e não escolhem os parâmetros físicos da sua simulação.
O fluxo é para dados reais (config_init_case = 7) e partida fria.

## 1. No computador: construir e abrir o ambiente

Use Bash no Linux, WSL ou Codespaces, com Docker instalado e em execução:

```bash
bash scripts/docker_mpas.sh build
bash scripts/docker_mpas.sh shell
```

O contêiner `mpas-container` é persistente. O comando `shell` o reabre quando já
existe. A pasta local `run/` é montada em `/mpas/run`; `dados-era5/` em
`/dados/era5`; e os scripts são montados em `/workspace/scripts` como somente leitura.
Os arquivos criados no volume podem pertencer ao root do contêiner.

Para usar outra pasta ou outro nome, defina as variáveis na primeira criação:

```bash
CONTAINER=mpas-outro RUN_DIR_HOST=/caminho/do/caso bash scripts/docker_mpas.sh shell
```

Reabrir um contêiner existente preserva seus volumes e sua imagem original.
Após reconstruir a imagem, use um nome novo para criar outro contêiner a partir dela.
Não remova seu contêiner antigo enquanto precisar da compilação armazenada nele.

## 2. Dentro do contêiner: compilar

```bash
bash /workspace/scripts/mpas.sh compile
```

Por padrão, são usadas duas tarefas de compilação para limitar o consumo de RAM.
Pode ajustar com `JOBS=4`. O script limpa a árvore de compilação entre os cores,
copia cada executável antes da limpeza seguinte e copia os namelists, streams,
listas de campos e tabelas físicas para `/mpas/run`.
Arquivos de configuração existentes nessa pasta são preservados; isso também
significa que configurações antigas não são atualizadas automaticamente.

## 3. Entradas externas e configuração

Coloque a malha NetCDF e o grafo em `/mpas/run`. Disponibilize também os dados
geográficos extraídos dentro do contêiner (por exemplo, em uma subpasta do volume
`/mpas/run/geog`). Para ERA5, compile o `ungrib` do WPS e converta os GRIB para
arquivos intermediários antes de executar a inicialização meteorológica.

O Dockerfile atual baixa o WPS, mas não compila o ungrib nem instala Jasper.
O script `prepare_wps_era5.sh` existente não conclui a conversão dos GRIB.
Portanto, essa preparação continua sendo um pré-requisito manual.

Para uma simulação global, os campos meteorológicos precisam cobrir toda a malha;
um recorte apenas de Goiás não é suficiente. Data e hora do ERA5, arquivos
intermediários, namelists e condições iniciais devem corresponder entre si.

Para quatro processos, por exemplo:

```bash
NP=4 bash /workspace/scripts/mpas.sh partition /mpas/run/x1.10242.graph.info
```

O script cria `x1.10242.graph.info.part.4`. Nos dois namelists, configure:

```fortran
&decomposition
 config_block_decomp_file_prefix = 'x1.10242.graph.info.part.'
/
```

Não acrescente o número 4 ao prefixo: o MPAS o adiciona automaticamente.
O mesmo NP deve ser usado ao particionar e executar. NP=1 dispensa a partição.

## 4. Gerar campos estáticos

Edite `/mpas/run/namelist.init_atmosphere` e `streams.init_atmosphere`.
No namelist, configure explicitamente `config_init_case = 7`,
`config_static_interp = .true.`, `config_met_interp = .false.` e
`config_geog_data_path` para o diretório dos dados geográficos.
Revise as demais opções de pré-processamento de acordo com o guia do MPAS.
Nos streams, a entrada deve apontar para a malha e a saída para o NetCDF estático.

```bash
NP=1 bash /workspace/scripts/mpas.sh check static
NP=1 bash /workspace/scripts/mpas.sh static
```

Usar um processo nesta etapa dispensa preparar uma partição adicional.
Se optar por mais processos, gere a partição correspondente primeiro.

## 5. Gerar condições iniciais

Depois da etapa estática, ajuste os mesmos arquivos `namelist.init_atmosphere`
e `streams.init_atmosphere` para a inicialização meteorológica:

- `config_init_case = 7`;
- `config_static_interp = .false.`;
- `config_met_interp = .true.`;
- `config_vertical_grid` e demais estágios conforme o caso;
- `config_start_time` correspondente ao ERA5;
- `config_met_prefix` correspondente aos arquivos intermediários do WPS;
- entrada dos streams apontando para o NetCDF estático;
- saída dos streams apontando para as condições iniciais, por exemplo `init.nc`.

```bash
NP=4 bash /workspace/scripts/mpas.sh check init
NP=4 bash /workspace/scripts/mpas.sh init
```

Os comandos static e init não reescrevem os namelists e streams. Cada um verifica
se as opções essenciais correspondem ao estágio pedido antes de chamar o MPAS.

## 6. Executar a atmosfera

Ajuste `namelist.atmosphere`: data inicial igual à das condições iniciais,
duração, passo de tempo compatível com a malha, suite física e decomposição.
Use `config_do_restart = .false.` para a partida fria deste fluxo.
Revise opções de SST e limites laterais conforme o caso; arquivos adicionais
podem ser necessários quando essas opções estiverem habilitadas.
Em `streams.atmosphere`, configure o stream `input` para ler `init.nc` e
configure nomes e intervalos das saídas.

```bash
NP=4 bash /workspace/scripts/mpas.sh check atmosphere
NP=4 bash /workspace/scripts/mpas.sh run
```

As saídas são gravadas em `/mpas/run` conforme os nomes definidos nos streams.
Falhas do MPI são retornadas pelo script com o mesmo código de saída.

## Alcance das verificações e testes

`check` verifica arquivos essenciais, XML dos streams, listas de campos,
permissão do executável, partição e algumas opções de inicialização. Ele não
verifica a integridade NetCDF, a cobertura global, a existência de todos os
campos ERA5, todas as tabelas físicas nem a estabilidade numérica. Mesmo após
passar, o MPAS ainda pode detectar problemas específicos da configuração.

Os testes dos scripts usam ferramentas simuladas: não compilam nem executam
uma simulação científica. Execute na raiz do repositório:

```bash
python3 -m unittest discover -s tests -v
bash -n scripts/mpas.sh scripts/docker_mpas.sh
```

Referências: [execução do MPAS](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/users_guide/running.html)
e [particionamento de malhas](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/users_guide/preparing_meshes.html).

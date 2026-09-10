# Design: baseline reproduzível MPAS + ERA5 (x1.10242)

## Objetivo

Adicionar ao repositório `MPAS_Compilation` um caso oficial de referência, pequeno e reproduzível, que complemente o foco atual em compilação com um pipeline completo de preparação, execução e validação do MPAS-Atmosphere.

A implementação deve preservar a filosofia atual do projeto: o ambiente continuará ensinando a construção da stack científica e a compilação manual, mas também passará a oferecer um caso de teste end-to-end verificável e scripts para automatizar as etapas repetitivas.

## Baseline oficial

O caso de referência será fixado com os seguintes parâmetros:

- MPAS-Atmosphere: `v8.4.1`;
- malha global: `x1.10242`;
- resolução aproximada: 240 km;
- ERA5 inicial: `2014-09-10 00 UTC`;
- duração da integração: 1 hora;
- `dt = 1200 s`;
- execução: 4 ranks MPI;
- runtime MPI preservado no projeto: MPICH;
- sistema base: Ubuntu 24.04.

A baseline deverá validar integração e sanidade básica do pipeline. Ela não deverá ser apresentada como avaliação de skill meteorológico, spin-up, desempenho multiday ou escalabilidade de produção.

## Arquitetura proposta

A estrutura será ampliada para separar claramente caso, scripts, testes e documentação:

```text
MPAS_Compilation/
├── cases/
│   └── first-global-240km/
│       ├── era5/
│       ├── wps/
│       ├── static/
│       ├── init/
│       └── atmosphere/
├── scripts/
│   ├── data/
│   ├── prepare/
│   ├── run/
│   └── validate/
├── tests/
│   └── smoke/
└── docs/
    ├── cases/
    ├── reproducibility/
    ├── testing/
    └── superpowers/specs/
```

Os arquivos grandes de entrada e saída científica permanecerão fora do Git. O repositório versionará configurações, scripts, requests ERA5, pequenos manifests e evidências leves de validação.

## Fluxo do caso

O pipeline será organizado como:

```text
ERA5
  -> GRIB
  -> WPS/ungrib
  -> WPS intermediate
  -> init_atmosphere (modo static)
  -> static.nc
  -> init_atmosphere (modo init)
  -> init.nc
  -> atmosphere_model
  -> history / diagnostics
  -> validação estrutural e sanity científico
```

Cada etapa deverá poder ser executada separadamente e também em sequência por um único comando end-to-end.

## Compatibilidade com a stack atual

A implementação não trocará MPICH por OpenMPI e não substituirá a arquitetura atual das dependências apenas para reproduzir outro projeto.

Serão preservados:

- MPICH e os wrappers `mpicc`, `mpicxx` e `mpif90`;
- HDF5 paralelo já utilizado no projeto;
- a organização atual das dependências;
- o caráter didático de permitir compilação manual do WPS e do MPAS.

Onde necessário, versões poderão ser ajustadas somente se houver incompatibilidade comprovada com a baseline. Qualquer mudança de versão deverá ser documentada e testada.

## Componentes a adicionar

### 1. Caso versionado

`cases/first-global-240km/` conterá as configurações mínimas para reproduzir a baseline:

- requests ERA5 versionadas;
- configuração do WPS/ungrib;
- namelists e streams do `init_atmosphere`;
- namelist e streams do `atmosphere_model`;
- referência à malha `x1.10242` sem versionar arquivos grandes;
- parâmetros explícitos de data, duração, `dt` e número de ranks.

### 2. Scripts de automação

Os scripts serão divididos por responsabilidade e deverão ser idempotentes quando possível: executar novamente uma etapa já concluída não deve destruir resultados válidos nem repetir downloads desnecessários.

Serão previstos pelo menos os seguintes comandos:

- `scripts/data/download_era5.py`: baixar os campos ERA5 necessários para `2014-09-10 00 UTC`, lendo credenciais somente do host;
- `scripts/data/fetch_mesh.sh`: obter ou validar a presença da malha `x1.10242` e dos dados geográficos necessários;
- `scripts/prepare/build_tools.sh`: verificar/compilar `ungrib.exe`, `init_atmosphere_model` e `atmosphere_model` quando ainda não estiverem disponíveis;
- `scripts/prepare/prepare_wps.sh`: criar links GRIB, selecionar a Vtable, configurar o período e executar `ungrib.exe`;
- `scripts/prepare/generate_static.sh`: preparar os arquivos e executar `init_atmosphere_model` para gerar `static.nc`;
- `scripts/prepare/generate_init.sh`: combinar `static.nc` e os campos meteorológicos processados para gerar `init.nc`;
- `scripts/run/run_atmosphere.sh`: executar a baseline de uma hora com `mpiexec -n 4` e os namelists oficiais do caso;
- `scripts/validate/preflight.sh`: verificar ferramentas, versões, arquivos e variáveis antes de iniciar etapas caras;
- `scripts/validate/validate_outputs.py`: validar dimensões, tempos, valores não finitos e campos essenciais nos NetCDFs;
- `scripts/validate/final_case.sh`: executar todos os testes finais e produzir resumo PASS/FAIL;
- `scripts/run/full_pipeline.sh`: orquestrar todas as etapas do caso, da verificação inicial até a validação final.

O script atual `scripts/prepare_wps_era5.sh` será reaproveitado, dividido em funções menores e mantido temporariamente como wrapper de compatibilidade, apontando para os novos scripts em vez de duplicar lógica.

### 3. Interface de automação

O usuário deverá poder executar o caso em níveis diferentes:

```text
./scripts/validate/preflight.sh
./scripts/prepare/build_tools.sh
./scripts/prepare/prepare_wps.sh
./scripts/prepare/generate_static.sh
./scripts/prepare/generate_init.sh
./scripts/run/run_atmosphere.sh
./scripts/validate/final_case.sh
```

ou executar o pipeline inteiro:

```text
./scripts/run/full_pipeline.sh
```

O pipeline completo deverá:

1. validar o ambiente;
2. verificar/obter entradas externas;
3. evitar novo download se os arquivos válidos já existirem;
4. preparar ERA5 com WPS;
5. gerar `static.nc`;
6. gerar `init.nc`;
7. executar o `atmosphere_model` em 4 ranks;
8. validar os produtos;
9. imprimir um resumo final com cada etapa marcada como PASS ou FAIL.

### 4. Configuração por variáveis

Os scripts deverão aceitar configurações por variáveis de ambiente, mantendo valores padrão da baseline. Entre elas:

- `CASE_ROOT`;
- `DATA_ROOT`;
- `MPAS_ROOT`;
- `WPS_ROOT`;
- `MESH_FILE`;
- `WPS_GEOG`;
- `MPI_RANKS` (padrão `4`);
- `START_DATE` (padrão `2014-09-10_00:00:00`);
- `RUN_DURATION` (padrão `01:00:00`);
- `DT` (padrão `1200`).

Isso permitirá reutilizar os scripts sem esconder os valores oficiais do teste.

### 5. Smoke tests

Os smoke tests deverão verificar, no mínimo:

- presença e versão das bibliotecas essenciais;
- funcionamento de MPI com 4 ranks;
- linkagem do MPAS com NetCDF/PnetCDF/PIO;
- disponibilidade de `ungrib.exe`;
- disponibilidade de `init_atmosphere_model`;
- disponibilidade de `atmosphere_model`;
- leitura de um artefato NetCDF simples;
- comportamento dos scripts quando entradas obrigatórias estão ausentes;
- comportamento de reexecução quando uma etapa já possui saída válida.

### 6. Teste end-to-end do caso

A validação oficial do caso deverá confirmar:

- ERA5 convertido pelo WPS sem erro crítico;
- geração de `static.nc`;
- geração de `init.nc`;
- execução de 1 hora do `atmosphere_model` com 4 ranks MPI;
- geração de history e diagnostics;
- integridade básica dos NetCDFs;
- ausência de NaN/Inf em campos-chave selecionados;
- coerência mínima de dimensões, tempo e coordenadas;
- saída final com status PASS/FAIL por etapa.

A validação não deverá classificar a previsão como meteorologicamente boa ou ruim. O escopo é integração, estabilidade numérica inicial e sanidade dos artefatos.

## Mudanças no código existente

A implementação não será somente aditiva. Arquivos existentes deverão ser alterados quando isso reduzir duplicação ou tornar o fluxo reproduzível.

Mudanças previstas:

- reorganizar `scripts/prepare_wps_era5.sh` para reutilizar as novas funções de preparação;
- ampliar `.gitignore` para cobrir GRIB, WPS intermediate, malhas, NetCDFs, logs e resultados locais;
- atualizar o `Dockerfile` para garantir que as dependências necessárias aos scripts e validadores estejam disponíveis;
- adicionar verificações de versão e linkagem no Dockerfile onde forem úteis, sem transformar o build didático em uma caixa-preta;
- atualizar `README.md` com comandos rápidos de build, preparação, execução e validação;
- completar a documentação atualmente vazia de WPS/ungrib;
- padronizar caminhos e variáveis do ambiente para evitar valores hardcoded espalhados pelos scripts.

## Estratégia de compilação

O repositório continuará permitindo a compilação manual como caminho didático principal.

Também haverá um caminho automatizado de preparação para testes, capaz de produzir ou verificar:

- `ungrib.exe`;
- `init_atmosphere_model`;
- `atmosphere_model`.

Esse caminho não deverá esconder os comandos reais de compilação. Os comandos e as opções usadas devem aparecer na documentação e nos logs de validação.

## Dados e credenciais

Credenciais do CDS nunca deverão ser versionadas nem copiadas para a imagem Docker.

A configuração deve esperar a credencial no host, por exemplo em `~/.cdsapirc`, montada somente quando necessária.

Arquivos grandes, incluindo GRIB, WPS intermediate, malhas, `static.nc`, `init.nc`, history, diagnostics e imagens Docker, deverão permanecer fora do Git e ser cobertos pelo `.gitignore`.

## Tratamento de erros

Cada script deverá usar falha explícita e mensagens acionáveis.

Exemplos de condições que devem interromper a execução:

- credencial ERA5 ausente;
- arquivo de malha ausente;
- `ungrib.exe` não encontrado;
- executável MPAS ausente;
- biblioteca não resolvida por `ldd`;
- NetCDF de entrada inválido;
- job MPI retornando código diferente de zero;
- arquivo esperado não criado;
- presença de erro crítico nos logs.

A mensagem de erro deverá indicar a etapa e o próximo comando/documento recomendado.

## Logs e rastreabilidade

Cada etapa automatizada deverá produzir logs em um diretório previsível, por exemplo `work/logs/`, e preservar os comandos efetivamente executados.

O pipeline final deverá registrar pelo menos:

- versões da stack;
- parâmetros da baseline;
- quantidade de ranks MPI;
- caminhos das entradas;
- checksums das configurações versionadas quando aplicável;
- código de saída das etapas;
- resumo PASS/FAIL.

Isso permitirá diagnosticar falhas sem depender apenas da saída do terminal.

## Documentação

Serão adicionados:

- `docs/cases/first-global-240km.md`: descrição científica e computacional da baseline;
- `docs/reproducibility/end-to-end.md`: do clone ao resultado final;
- `docs/testing/validation-matrix.md`: matriz de verificações e critérios PASS/FAIL;
- documentação complementar de WPS/ungrib para preencher as lacunas atuais.

O README principal deverá apontar para o caso de referência e explicar claramente a diferença entre:

- construir o ambiente;
- compilar o software;
- preparar as entradas;
- executar smoke tests;
- reproduzir o caso completo;
- realizar sanity científico.

## Critérios de sucesso

A implementação será considerada concluída quando um usuário, partindo de um clone limpo e das entradas externas documentadas, conseguir:

1. construir ou abrir o ambiente;
2. verificar a stack com smoke tests;
3. obter/preparar os dados ERA5 necessários;
4. produzir `static.nc` e `init.nc`;
5. executar uma hora de MPAS-Atmosphere em 4 ranks MPI;
6. gerar history/diagnostics;
7. executar um validador final que reporte PASS para integração, NetCDFs e sanity básico;
8. reproduzir tudo com `./scripts/run/full_pipeline.sh` sem editar scripts manualmente.

## Fora de escopo

Não fazem parte desta entrega:

- benchmark de escalabilidade;
- execução multiday;
- GPU/OpenACC/OpenMP offload;
- comparação de desempenho MPICH vs OpenMPI;
- validação de forecast skill;
- assimilação de dados;
- substituição completa do modelo didático de compilação manual.

## Estratégia de implementação recomendada

A implementação deverá ser incremental:

1. criar estrutura do caso e manifests;
2. criar preflight e convenções de caminhos;
3. estabilizar aquisição/preparo ERA5 + WPS;
4. adicionar smoke tests da stack;
5. automatizar static e init;
6. automatizar a execução de 1 hora;
7. adicionar validação final;
8. criar `full_pipeline.sh`;
9. atualizar Dockerfile, README e documentação.

Cada etapa deverá ser testável de forma independente, reduzindo o risco de um único script monolítico difícil de diagnosticar.

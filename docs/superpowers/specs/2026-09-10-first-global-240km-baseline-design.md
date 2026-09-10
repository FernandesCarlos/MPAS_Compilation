# Design: baseline reproduzível MPAS + ERA5 (x1.10242)

## Objetivo

Adicionar ao repositório `MPAS_Compilation` um caso oficial de referência, pequeno e reproduzível, que complemente o foco atual em compilação com um pipeline completo de preparação, execução e validação do MPAS-Atmosphere.

A implementação deve preservar a filosofia atual do projeto: o ambiente continuará ensinando a construção da stack científica e a compilação manual, mas também passará a oferecer um caso de teste end-to-end verificável.

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

Cada etapa deverá poder ser executada separadamente e também em sequência por um guia end-to-end.

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

### 2. Scripts

Os scripts serão divididos por responsabilidade:

- `scripts/data/`: aquisição e verificação de ERA5 e demais entradas;
- `scripts/prepare/`: WPS, static e init;
- `scripts/run/`: execução do MPAS;
- `scripts/validate/`: preflight, integridade e sanity checks.

O script atual `scripts/prepare_wps_era5.sh` será reaproveitado e reorganizado, evitando duplicação de lógica.

### 3. Smoke tests

Os smoke tests deverão verificar, no mínimo:

- presença e versão das bibliotecas essenciais;
- funcionamento de MPI com 4 ranks;
- linkagem do MPAS com NetCDF/PnetCDF/PIO;
- disponibilidade de `ungrib.exe`;
- disponibilidade de `init_atmosphere_model`;
- disponibilidade de `atmosphere_model`;
- leitura de um artefato NetCDF simples;
- falha clara quando uma dependência obrigatória estiver ausente.

### 4. Teste end-to-end do caso

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

## Estratégia de compilação

O repositório continuará permitindo a compilação manual como caminho didático principal.

Será criado um caminho opcional de preparação automatizada para testes, capaz de produzir ou verificar:

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

## Documentação

Serão adicionados:

- `docs/cases/first-global-240km.md`: descrição científica e computacional da baseline;
- `docs/reproducibility/end-to-end.md`: do clone ao resultado final;
- `docs/testing/validation-matrix.md`: matriz de verificações e critérios PASS/FAIL;
- documentação complementar de WPS/ungrib para preencher as lacunas atuais.

O README principal deverá apontar para o caso de referência e explicar claramente a diferença entre:

- construir o ambiente;
- compilar o software;
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
7. executar um validador final que reporte PASS para integração, NetCDFs e sanity básico.

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
2. estabilizar aquisição/preparo ERA5 + WPS;
3. adicionar smoke tests da stack;
4. automatizar static e init;
5. automatizar a execução de 1 hora;
6. adicionar validação final;
7. completar documentação e README.

Cada etapa deverá ser testável de forma independente, reduzindo o risco de um único script monolítico difícil de diagnosticar.

#!/usr/bin/env bash
# Comandos dentro do contêiner; use bash /workspace/scripts/mpas.sh help.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RUN_DIR=${RUN_DIR:-/mpas/run}
MPAS_SOURCE=${MPAS_SOURCE:-/mpas/MPAS-Model}
NP=${NP:-4}
JOBS=${JOBS:-2}

fail() { echo "ERRO: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || fail "Comando não encontrado: $1"; }
positive() { [[ "$2" =~ ^[1-9][0-9]*$ ]] || fail "$1 deve ser um inteiro positivo."; }
usage() {
    cat <<'EOF'
Uso: bash mpas.sh compile|partition GRAFO|check ETAPA|static|init|run
  compile         Compila os dois cores e copia executáveis/configurações/tabelas.
  partition GRAFO Particiona um arquivo graph.info para NP processos.
  check ETAPA     Verifica arquivos; ETAPA: static, init ou atmosphere.
  static          Executa init_atmosphere no modo estático configurado.
  init            Executa init_atmosphere no modo meteorológico configurado.
  run             Executa atmosphere_model com as condições iniciais preparadas.
Variáveis: RUN_DIR=/mpas/run, MPAS_SOURCE=/mpas/MPAS-Model, NP=4, JOBS=2.
Os comandos static/init/run exigem namelists e streams ajustados ao seu caso.
As configurações existentes em RUN_DIR são preservadas durante compile.
EOF
}
copy_default() {
    local src=$1 dst="$RUN_DIR/$(basename -- "$1")"
    if [[ ! -e "$dst" && ! -L "$dst" ]]; then
        cp -- "$src" "$dst"
    else
        echo "Preservando configuração: $dst"
    fi
}
compile() {
    need make
    positive JOBS "$JOBS"
    [[ -f "$MPAS_SOURCE/Makefile" ]] || fail "Código-fonte ausente em $MPAS_SOURCE."
    mkdir -p -- "$RUN_DIR"
    RUN_DIR=$(cd -- "$RUN_DIR" && pwd)
    MPAS_SOURCE=$(cd -- "$MPAS_SOURCE" && pwd)
    [[ "$RUN_DIR" != "$MPAS_SOURCE" ]] || fail "RUN_DIR deve ser diferente do código-fonte."
    cd -- "$MPAS_SOURCE"
    local core f
    for core in init_atmosphere atmosphere; do
        make clean "CORE=$core"
        make "-j$JOBS" gnu "CORE=$core" USE_PIO2=true
        [[ -x "${core}_model" ]] || fail "Build não gerou ${core}_model."
        cp -- "${core}_model" "$RUN_DIR/"
        for f in "namelist.$core" "streams.$core"; do
            [[ -s "$f" ]] || fail "Build não gerou $f."
            copy_default "$f"
        done
        for f in stream_list."$core".*; do
            [[ ! -f "$f" ]] || copy_default "$f"
        done
    done
    local tables="$MPAS_SOURCE/src/core_atmosphere/physics/physics_wrf/files"
    [[ -d "$tables" ]] || fail "Diretório de tabelas físicas ausente: $tables"
    for f in "$tables"/*; do
        [[ ! -f "$f" ]] || copy_default "$f"
    done
    echo "Executáveis copiados para $RUN_DIR. Ajuste os namelists e streams antes de executar."
}
check() {
    positive NP "$NP"
    need python3
    [[ -d "$RUN_DIR" ]] || fail "Diretório de execução ausente: $RUN_DIR"
    python3 "$SCRIPT_DIR/check_mpas_case.py" "$RUN_DIR" "$1" "$NP"
}
launch() {
    local stage=$1 exe=$2
    check "$stage"
    need mpirun
    cd -- "$RUN_DIR"
    echo "Executando $exe com $NP processos em $PWD"
    # exec preserva o código de saída do MPI, inclusive em caso de falha.
    exec mpirun -np "$NP" "./$exe"
}

command=${1:-help}
case "$command" in
    help|-h|--help) usage ;;
    compile) [[ $# -eq 1 ]] || fail "Uso: mpas.sh compile"; compile ;;
    partition)
        [[ $# -eq 2 ]] || fail "Uso: mpas.sh partition /caminho/malha.graph.info"
        positive NP "$NP"
        [[ "$NP" -gt 1 ]] || fail "Uma execução com NP=1 não precisa de partição."
        [[ -s "$2" ]] || fail "Grafo ausente ou vazio: $2"
        need gpmetis
        mkdir -p -- "$RUN_DIR"
        graph=$(realpath -- "$2")
        gpmetis -minconn -contig -niter=200 "$graph" "$NP"
        part="${graph}.part.${NP}"
        [[ -s "$part" ]] || fail "METIS não gerou $part."
        target="$(cd -- "$RUN_DIR" && pwd)/$(basename -- "$part")"
        [[ "$part" == "$target" ]] || cp -- "$part" "$target"
        echo "Partição: $target"
        echo "No namelist, use config_block_decomp_file_prefix = '$(basename -- "$graph").part.'"
        ;;
    check)
        [[ $# -eq 2 ]] || fail "Uso: mpas.sh check static|init|atmosphere"
        check "$2"
        ;;
    static|init)
        [[ $# -eq 1 ]] || fail "Uso: mpas.sh $command"
        launch "$command" init_atmosphere_model
        ;;
    run)
        [[ $# -eq 1 ]] || fail "Uso: mpas.sh run"
        launch atmosphere atmosphere_model
        ;;
    *) usage >&2; fail "Comando desconhecido: $command" ;;
esac

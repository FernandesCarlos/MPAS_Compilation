#!/usr/bin/env bash
# Execute este script no host Linux/WSL/Codespaces, na cópia do repositório.
set -euo pipefail
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${IMAGE:-mpas}
CONTAINER=${CONTAINER:-mpas-container}
RUN_DIR_HOST=${RUN_DIR_HOST:-$PROJECT_DIR/run}
DATA_DIR_HOST=${DATA_DIR_HOST:-$PROJECT_DIR/dados-era5}
fail() { echo "ERRO: $*" >&2; exit 1; }
command=${1:-help}
case "$command" in
    help|-h|--help)
        echo 'Uso: bash scripts/docker_mpas.sh build|shell'
        echo 'build: constrói a imagem; shell: cria ou reabre o contêiner persistente.'
        echo 'Variáveis: IMAGE, CONTAINER, RUN_DIR_HOST, DATA_DIR_HOST.'
        exit 0 ;;
    build|shell) [[ $# -eq 1 ]] || fail "Uso: docker_mpas.sh $command" ;;
    *) fail "Comando desconhecido: $command" ;;
esac
command -v docker >/dev/null || fail 'Instale/inicie o Docker antes de continuar.'
docker info >/dev/null 2>&1 || fail 'O serviço Docker não está acessível.'
if [[ "$command" == build ]]; then
    exec docker build -t "$IMAGE" "$PROJECT_DIR"
fi
mkdir -p -- "$RUN_DIR_HOST" "$DATA_DIR_HOST"
RUN_DIR_HOST=$(cd -- "$RUN_DIR_HOST" && pwd)
DATA_DIR_HOST=$(cd -- "$DATA_DIR_HOST" && pwd)
if docker container inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "Reabrindo $CONTAINER com a imagem e os volumes usados na sua criação."
    if [[ "$(docker inspect --format '{{.State.Running}}' "$CONTAINER")" == true ]]; then
        exec docker exec -it "$CONTAINER" bash
    else
        exec docker start -ai "$CONTAINER"
    fi
fi
exec docker run -it --name "$CONTAINER" \
    --mount "type=bind,source=$RUN_DIR_HOST,target=/mpas/run" \
    --mount "type=bind,source=$DATA_DIR_HOST,target=/dados/era5" \
    --mount "type=bind,source=$PROJECT_DIR/scripts,target=/workspace/scripts,readonly" \
    "$IMAGE" bash
